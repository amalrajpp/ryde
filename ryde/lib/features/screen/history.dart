import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ride_tracking_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Helper: Calculate seats
  String _getSeats(String? vehicleType) {
    final type = vehicleType?.toLowerCase() ?? 'car';
    if (type.contains('bike')) return '1 Seat';
    if (type.contains('auto')) return '3 Seats';
    return '4 Seats';
  }

  // Helper: Format Date
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F6F9),
          elevation: 0,
          title: const Text(
            'My Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              height: 50,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                // 1. Makes the black bubble fill the exact width of the tab
                indicatorSize: TabBarIndicatorSize.tab,
                // 2. Removes the default bottom line found in newer Flutter versions
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                // 3. Much cleaner tabs list
                tabs: const [
                  Tab(text: "Ongoing"),
                  Tab(text: "History"),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              // 1. QUERY SORT: Fetches data newest first from server
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // Filter Logic
            final ongoing = docs.where((d) {
              final s = (d['status'] ?? '').toString().toLowerCase();
              return [
                'confirmed',
                'driver_assigned',
                'on_way',
                'started',
                'on_trip',
              ].contains(s);
            }).toList();

            final history = docs.where((d) {
              final s = (d['status'] ?? '').toString().toLowerCase();
              return ['completed', 'cancelled', 'paid'].contains(s);
            }).toList();

            // 2. CLIENT-SIDE SORT SAFETY:
            // Ensures strict order even during local updates (latency compensation)
            // where 'created_at' might be momentarily null or unordered.
            int sortFunc(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
              Timestamp? t1 = a['created_at'] as Timestamp?;
              Timestamp? t2 = b['created_at'] as Timestamp?;
              if (t1 == null) return -1; // Show pending writes at top
              if (t2 == null) return 1;
              return t2.compareTo(t1); // Descending
            }

            ongoing.sort(sortFunc);
            history.sort(sortFunc);

            return TabBarView(
              children: [
                _buildList(
                  context,
                  ongoing,
                  "No active deliveries",
                  isHistory: false,
                ),
                _buildList(
                  context,
                  history,
                  "No past history",
                  isHistory: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String emptyMsg, {
    required bool isHistory,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (ctx, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final id = docs[i].id;

        // Extract Vehicle Type safely
        final vehicleMap = data['vehicle'] as Map<String, dynamic>? ?? {};
        final vehicleType = vehicleMap['type'] ?? 'Car';

        return _RideCard(
          data: data,
          formattedDate: _formatDate(data['created_at'] as Timestamp?),
          seats: _getSeats(vehicleType),
          vehicleType: vehicleType,
          isHistory: isHistory,
          onTrackPressed: () {
            if (!isHistory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RideTrackingScreen(bookingId: id, bookingData: data),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// --- FULLY FEATURED CARD ---
class _RideCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String formattedDate;
  final String seats;
  final String vehicleType;
  final bool isHistory;
  final VoidCallback onTrackPressed;

  const _RideCard({
    super.key,
    required this.data,
    required this.formattedDate,
    required this.seats,
    required this.vehicleType,
    required this.isHistory,
    required this.onTrackPressed,
  });

  @override
  Widget build(BuildContext context) {
    const String googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";

    final route = data['route'] as Map<String, dynamic>? ?? {};
    final String pickup = route['pickup_address'] ?? "Unknown";
    final String dropoff = route['dropoff_address'] ?? "Unknown";
    final double lat = (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
    final double lng = (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;

    final String driverName = data['driver_name'] ?? "Unknown Driver";
    final String status = (data['status'] ?? "Pending").toString();
    final double price = (data['price'] as num?)?.toDouble() ?? 0.0;

    // Logic for Payment Status
    bool isPaid =
        status.toLowerCase() == 'completed' || status.toLowerCase() == 'paid';
    String paymentStatus = isPaid ? "Paid" : "Pending";
    Color paymentColor = isPaid ? Colors.green : Colors.orange;

    // Map Image
    final String mapUrl =
        "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=14&size=160x160&markers=color:red%7C$lat,$lng&key=$googleApiKey";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Map & Addresses
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[100],
                        image: DecorationImage(
                          image: NetworkImage(mapUrl),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationRow(
                            Icons.my_location,
                            pickup,
                            Colors.blue,
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              left: 9,
                              top: 4,
                              bottom: 4,
                            ),
                            height: 10,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _buildLocationRow(
                            Icons.location_on,
                            dropoff,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. INFO BOX (Restored Missing Fields)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Date & Time", formattedDate),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _buildDetailRow("Vehicle", "$vehicleType • $seats"),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _buildDetailRow("Driver", driverName),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      // Payment Status Row with Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Payment Status",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                paymentStatus,
                                style: TextStyle(
                                  color: paymentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "• ₹${price.toInt()}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. TRACK / SUMMARY BUTTON
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          InkWell(
            onTap: isHistory ? null : onTrackPressed,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isHistory ? Colors.transparent : const Color(0xFF3B82F6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Text(
                isHistory ? "View Summary" : "Track Ride",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHistory ? Colors.white : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Info Rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper for Address Rows
  Widget _buildLocationRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
