-- ========================================================
-- RIDER FEATURE MIGRATION FOR TIKBOY LONGANISA (FIXED RLS & IDEMPOTENT)
-- Run this complete script in your Supabase SQL Editor.
-- ========================================================

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    role TEXT CHECK (role IN ('customer', 'rider', 'admin')) DEFAULT 'customer',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin (avoids infinite recursion in RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles Policies
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
CREATE POLICY "Users can read their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;
CREATE POLICY "Admins can read all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "Users can update their profile except role" ON public.profiles;
CREATE POLICY "Users can update their profile except role"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

-- 3. Auto-create profile trigger on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Customer'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Update orders table (add rider_id, user_id, and ensure status check)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'rider_id') THEN
        ALTER TABLE public.orders ADD COLUMN rider_id UUID REFERENCES public.profiles(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'user_id') THEN
        ALTER TABLE public.orders ADD COLUMN user_id UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- Check constraint on order status
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check CHECK (status IN ('Pending', 'placed', 'confirmed', 'out_for_delivery', 'delivered', 'Cancelled', 'Refund Requested', 'Refunded'));

-- Enable RLS on orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Orders Policies
DROP POLICY IF EXISTS "Customers can read their own orders" ON public.orders;
CREATE POLICY "Customers can read their own orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Riders can read assigned orders" ON public.orders;
CREATE POLICY "Riders can read assigned orders"
    ON public.orders FOR SELECT
    USING (rider_id = auth.uid());

DROP POLICY IF EXISTS "Admins have full access to orders" ON public.orders;
CREATE POLICY "Admins have full access to orders"
    ON public.orders FOR ALL
    USING (public.is_admin());

-- 5. Create deliveries table
CREATE TABLE IF NOT EXISTS public.deliveries (
    order_id UUID PRIMARY KEY REFERENCES public.orders(id) ON DELETE CASCADE,
    rider_id UUID REFERENCES public.profiles(id),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on deliveries
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;

-- Deliveries Policies
DROP POLICY IF EXISTS "Riders manage their assigned deliveries" ON public.deliveries;
CREATE POLICY "Riders manage their assigned deliveries"
    ON public.deliveries FOR ALL
    USING (rider_id = auth.uid())
    WITH CHECK (rider_id = auth.uid());

DROP POLICY IF EXISTS "Customers view delivery for their orders" ON public.deliveries;
CREATE POLICY "Customers view delivery for their orders"
    ON public.deliveries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE public.orders.id = public.deliveries.order_id
            AND (public.orders.user_id = auth.uid() OR public.orders.user_id IS NULL)
        )
    );

-- 6. Enable Realtime on deliveries table (idempotent)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.deliveries;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
