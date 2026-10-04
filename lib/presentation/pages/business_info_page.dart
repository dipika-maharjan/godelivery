import 'package:flutter/material.dart';

class BusinessInfoPage extends StatefulWidget {
  final String phoneNumber;

  const BusinessInfoPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _businessNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _businessNameController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _createAccount() {
    final fullName = _fullNameController.text.trim();
    final businessName = _businessNameController.text.trim();

    if (fullName.isEmpty || fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name must be at least 2 characters')),
      );
      return;
    }

    if (businessName.isEmpty || businessName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name must be at least 2 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Call AuthProvider.createUserAccount(
    //   fullName: fullName,
    //   businessName: businessName,
    // ) and navigate to dashboard on success

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Almost there!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us a little about your business.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                hintText: 'Enter your business/shop name',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
