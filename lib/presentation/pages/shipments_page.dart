import 'package:flutter/material.dart';
import '../widgets/shipment_card.dart';

class ShipmentsPage extends StatefulWidget {
  const ShipmentsPage({super.key});

  @override
  State<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<ShipmentsPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Pending', 'Delivered', 'Failed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        title: const Text('Shipments', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filters[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = index);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFFFFC107),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Shipment List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ShipmentCard(
                  id: 'ORD-${100001 + index}',
                  destination: 'Destination Address ${index + 1}',
                  weight: '45 kg',
                  status: _getStatus(index),
                  statusColor: _getStatusColor(index),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new shipment
        },
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Color _getStatusColor(int index) {
    switch (index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _getStatus(int index) {
    switch (index) {
      case 0:
        return 'Delivered';
      case 1:
        return 'In Transit';
      default:
        return 'Pending';
    }
  }
}
