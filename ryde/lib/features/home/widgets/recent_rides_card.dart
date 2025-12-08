import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screen/ride_tracking_screen.dart';

class RecentRidesCard extends StatefulWidget {
  const RecentRidesCard({super.key});

  @override
  State<RecentRidesCard> createState() => _RecentRidesCardState();
}

class _RecentRidesCardState extends State<RecentRidesCard> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  // --- Helper Methods ---
  String _getSeats(String? vehicleType) {
    final type = vehicleType?.toLowerCase() ?? 'car';
    if (type.contains('bike')) return '1 Seat';
    if (type.contains('auto')) return '3 Seats';
    return '4 Seats';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return _buildPlaceholderCard(
        icon: Icons.login,
        message: 'Please sign in to view recent rides',
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('booking')
        .where('customer_id', isEqualTo: _userId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildPlaceholderCard(
            icon: Icons.error_outline,
            message: 'Error loading rides: ${snapshot.error}',
            color: Colors.red,
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildPlaceholderCard(
            icon: Icons.history,
            message: 'No recent rides yet',
          );
        }

        // We only take the first one because of limit(1)
        final doc = docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;

        // Data Extraction
        final vehicleMap = data['vehicle'] as Map<String, dynamic>? ?? {};
        final vehicleType = vehicleMap['type'] ?? 'Car';
        final status = (data['status'] ?? 'Pending').toString();
        final route = data['route'] as Map<String, dynamic>? ?? {};
        final String pickup = route['pickup_address'] ?? "Unknown";
        final String dropoff = route['dropoff_address'] ?? "Unknown";
        final double lat = (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
        final double lng = (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;
        final String driverName = data['driver_name'] ?? "Unknown Driver";
        final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final formattedDate = _formatDate(data['created_at'] as Timestamp?);

        // Payment Logic
        bool isPaid =
            status.toLowerCase() == 'completed' ||
            status.toLowerCase() == 'paid';
        String paymentStatus = isPaid ? "Paid" : "Pending";
        Color paymentColor = isPaid ? Colors.green : Colors.orange;

        // Map URL
        const String googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";
        final String mapUrl =
            "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=14&size=160x160&markers=color:red%7C$lat,$lng&key=$googleApiKey";

        // Logic to determine if "Track Ride" should be enabled
        bool isOngoing = [
          'created',
          'accepted',
          'started',
          'ongoing',
        ].contains(status.toLowerCase());

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

                    // 2. INFO BOX
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
                          _buildDetailRow(
                            "Vehicle",
                            "$vehicleType • ${_getSeats(vehicleType)}",
                          ),
                          const Divider(height: 16, color: Color(0xFFEEEEEE)),
                          _buildDetailRow("Driver", driverName),
                          const Divider(height: 16, color: Color(0xFFEEEEEE)),
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

                    // --- View Delivery Details Button ---
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () => _showDeliveryDetails(context, data),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "View Delivery Details",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. ACTIONS AREA (Bottom Button)
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              InkWell(
                onTap: isOngoing
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideTrackingScreen(
                              bookingId: id,
                              bookingData: data,
                            ),
                          ),
                        );
                      }
                    : null, // Disable if completed/history
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent, // Highlight only if trackable
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Text(
                    isOngoing ? "Track Ride" : status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOngoing ? Colors.white : Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Sub-Widgets ---

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String message,
    Color color = Colors.grey,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: color, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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

  // --- Delivery Details Modal Logic (Copied from HistoryScreen) ---
  void _showDeliveryDetails(BuildContext context, Map<String, dynamic> data) {
    final pickupDetails = data['pickup_details'] as Map<String, dynamic>? ?? {};
    final dropoffDetails =
        data['dropoff_details'] as Map<String, dynamic>? ?? {};
    final parcelDetails = data['parcel_details'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delivery Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildModalDetailSection(
                title: "Pick-up Details",
                icon: Icons.upload_rounded,
                iconColor: Colors.blue,
                details: pickupDetails,
                defaultName: "Sender",
              ),
              const Divider(height: 40),
              _buildModalDetailSection(
                title: "Drop-off Details",
                icon: Icons.download_rounded,
                iconColor: Colors.red,
                details: dropoffDetails,
                defaultName: "Receiver",
              ),
              if (parcelDetails.isNotEmpty) ...[
                const Divider(height: 40),
                _buildModalParcelSection(parcelDetails),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetailSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, dynamic> details,
    required String defaultName,
  }) {
    final name = details['name']?.toString() ?? defaultName;
    final phone = details['phone']?.toString() ?? "No phone";
    final building = details['building']?.toString() ?? "No building info";
    final unit = details['unit']?.toString() ?? "";
    final instructions = details['instructions']?.toString() ?? "";
    final option = details['option']?.toString() ?? "Meet at curb";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Phone: +91 $phone",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                [building, unit, option].where((e) => e.isNotEmpty).join(" • "),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              if (instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructions,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModalParcelSection(Map<String, dynamic> details) {
    final weight = details['weight_range']?.toString() ?? "Unknown Weight";
    final type = details['type']?.toString() ?? "Parcel";
    final description = details['description']?.toString() ?? "";
    final dimensions = details['dimensions'] as Map<String, dynamic>? ?? {};

    String dimText = "";
    if (dimensions.isNotEmpty) {
      final l = dimensions['l']?.toString() ?? "";
      final w = dimensions['w']?.toString() ?? "";
      final h = dimensions['h']?.toString() ?? "";
      if (l.isNotEmpty && w.isNotEmpty && h.isNotEmpty) {
        dimText = "$l x $w x $h cm";
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Parcel Details",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$weight • $type",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (dimText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Dim: $dimText",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
