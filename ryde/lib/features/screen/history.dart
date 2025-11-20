import 'package:flutter/material.dart';

class PopularCarScreen extends StatelessWidget {
  const PopularCarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9), // Light grey background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Car',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Ascending',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Main Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Section: Map & Locations
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map Thumbnail
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://developers.google.com/static/maps/documentation/urls/images/map-no-params.png",
                              ), // Dummy map image
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Location Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLocationRow(
                                icon:
                                    Icons.navigation_outlined, // Triangle icon
                                text: "1901 Thornridge Cir. Shiloh",
                                iconRotation:
                                    1.5, // Rotates icon to point right
                              ),
                              const SizedBox(height: 12),
                              _buildLocationRow(
                                icon: Icons.location_on_outlined,
                                text: "4140 Parker Rd. Allentown",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bottom Section: Details List
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF8F9FB,
                        ), // Very light grey inside card
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            "Date & Time",
                            "16 July 2025, 10:30 PM",
                          ),
                          const Divider(height: 24, color: Color(0xFFEEEEEE)),
                          _buildDetailRow("Driver", "Jane Cooper"),
                          const Divider(height: 24, color: Color(0xFFEEEEEE)),
                          _buildDetailRow("Car seats", "4"),
                          const Divider(height: 24, color: Color(0xFFEEEEEE)),
                          _buildDetailRow(
                            "Payment Status",
                            "Paid",
                            valueColor: Colors.green, // Override color for Paid
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the Location rows (Top part)
  Widget _buildLocationRow({
    required IconData icon,
    required String text,
    double iconRotation = 0,
  }) {
    return Row(
      children: [
        RotatedBox(
          quarterTurns: iconRotation > 0 ? 1 : 0, // Simple rotation logic
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
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
          ),
        ),
      ],
    );
  }

  // Helper for the Details rows (Bottom part)
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF333333),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
