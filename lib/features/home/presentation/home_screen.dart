import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    _OrdersTab(),
    _ShipmentTab(),
    _CreateTab(),
    _AccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFF3C91F),
            unselectedItemColor: const Color(0xFF6B6B6B),
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.content_paste_rounded),
                label: 'Order',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_rounded),
                label: 'Shipment',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Create',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Orders',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ShipmentTab extends StatelessWidget {
  const _ShipmentTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Shipment',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  const _CreateTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Create',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Account',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }
}
