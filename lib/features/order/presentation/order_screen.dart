import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_OrderData> _orders = const [
    _OrderData(
      id: 'ORD-100001',
      destination: 'Destination Address 1',
      weight: '2 kg',
      status: 'Shipped',
      statusColor: Colors.green,
    ),
    _OrderData(
      id: 'ORD-100002',
      destination: 'Destination Address 2',
      weight: '2 kg',
      status: 'In Transit',
      statusColor: Colors.orange,
    ),
    _OrderData(
      id: 'ORD-100003',
      destination: 'Destination Address 3',
      weight: '2 kg',
      status: 'Packaged',
      statusColor: Color(0xFFD4A900),
    ),
    _OrderData(
      id: 'ORD-100004',
      destination: 'Destination Address 4',
      weight: '2 kg',
      status: 'Packaged',
      statusColor: Colors.black,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredOrders = _orders.where((order) {
      return query.isEmpty ||
          '${order.id} ${order.destination} ${order.status}'
              .toLowerCase()
              .contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 26, 20, 14),
              child: Text(
                'Your orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search your order',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB5B5B5),
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFE4E4E4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return _OrderCard(order: filteredOrders[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderData {
  const _OrderData({
    required this.id,
    required this.destination,
    required this.weight,
    required this.status,
    required this.statusColor,
  });

  final String id;
  final String destination;
  final String weight;
  final String status;
  final Color statusColor;
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _OrderData order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFFB18400),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jewelry Items - 10 pieces',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14),
                      const SizedBox(width: 4),
                      const Text('Jane Doe', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(Icons.scale_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(order.weight, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: order.statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: order.statusColor == Colors.black
                                ? Colors.white
                                : Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined, size: 12),
                      const SizedBox(width: 4),
                      const Text('12/12/2026', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}
