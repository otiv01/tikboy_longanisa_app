import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildUserStatistics(),
          const Divider(height: 32, thickness: 1),
          _buildListTile(Icons.person, 'Personal Information'),
          _buildListTile(Icons.location_on, 'Saved Addresses'),
          _buildListTile(Icons.favorite, 'My Favorites'),
          _buildListTile(Icons.history, 'Order History'),
          _buildListTile(Icons.star, 'Loyalty Points'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return const Row(
      children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 40, color: Colors.white)),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Juan Dela Cruz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Reseller Status: Active', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Loyalty Points: 1,250 pts', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatistics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Total Orders', '42'),
        _buildStatCard('Total Spent', '₱12,500'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}