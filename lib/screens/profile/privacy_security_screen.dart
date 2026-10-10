import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('SECURITY'),
            _buildSecurityItem(
              Icons.lock_outline,
              'Change Password',
              'Update your account password',
              onTap: () {},
            ),
            
            const SizedBox(height: 30),
            _buildSectionLabel('PRIVACY'),
            _buildSecurityItem(
              Icons.location_off_outlined,
              'Location Access',
              'Manage how we use your location',
              onTap: () {},
            ),
            
            const SizedBox(height: 30),
            _buildSectionLabel('LEGAL'),
            _buildSecurityItem(
              Icons.description_outlined,
              'Privacy Policy',
              'Read our data handling practices',
              onTap: () {},
            ),
            _buildSecurityItem(
              Icons.gavel_outlined,
              'Terms of Service',
              'App usage rules and agreements',
              onTap: () {},
            ),
            
            const SizedBox(height: 40),
            _buildDeleteAccountButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 22),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Permanently remove your data', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
        onTap: () {},
      ),
    );
  }
}
