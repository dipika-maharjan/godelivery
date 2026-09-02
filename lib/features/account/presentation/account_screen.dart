import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        title: const Text('Account', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: const Color(0xFFFFC107),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hello Shop',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '98XXXXXXXX',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Account Settings
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.store, color: Color(0xFFFFC107)),
                      title: const Text('Business Information'),
                      subtitle: const Text('Edit your business details'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to business profile edit page
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Color(0xFFFFC107)),
                      title: const Text('Personal Information'),
                      subtitle: const Text('Update your personal details'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to personal info edit page
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.notifications, color: Color(0xFFFFC107)),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage push notifications'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to notifications settings
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.lock, color: Color(0xFFFFC107)),
                      title: const Text('Password & Security'),
                      subtitle: const Text('Update password and security settings'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to password settings
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.help, color: Color(0xFFFFC107)),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Contact us or view FAQs'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to help page
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Call AuthProvider.logoutUser() and navigate to phone input
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/phone-input',
                                  );
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}