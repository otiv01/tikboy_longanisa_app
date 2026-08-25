import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())), // Full name field[cite: 1]
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())), // Email field[cite: 1]
            const SizedBox(height: 16),
            TextField(
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red button required by thesis[cite: 1]
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              child: const Text('Create Account', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 24),
            const Text('Or continue with', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {}, // Google login option[cite: 1]
                  icon: const Icon(Icons.g_mobiledata, color: Colors.black),
                  label: const Text('Google', style: TextStyle(color: Colors.black)),
                ),
                OutlinedButton.icon(
                  onPressed: () {}, // Facebook login option[cite: 1]
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                  label: const Text('Facebook', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Sign In', style: TextStyle(color: Colors.red)), // Sign in link[cite: 1]
            ),
          ],
        ),
      ),
    );
  }
}