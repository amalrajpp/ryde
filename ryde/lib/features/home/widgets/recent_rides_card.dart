import 'package:flutter/material.dart';

class RecentRidesCard extends StatelessWidget {
  const RecentRidesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Top image + locations
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/dummy-map.jpg",
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _RideAddressRow(
                      icon: Icons.location_on_outlined,
                      text: "1901 Thornridge Cir, Shiloh",
                    ),
                    SizedBox(height: 5),
                    _RideAddressRow(
                      icon: Icons.place_outlined,
                      text: "4140 Parker Rd, Allentown",
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),

          // Ride details
          _RideDetail(title: "Date & Time", value: "16 July 2025, 10:30 PM"),
          _RideDetail(title: "Driver", value: "Jane Cooper"),
          _RideDetail(title: "Car seats", value: "4"),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Payment Status",
                  style: TextStyle(color: Colors.grey)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("Paid",
                    style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sub-widgets
class _RideAddressRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RideAddressRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RideDetail extends StatelessWidget {
  final String title;
  final String value;

  const _RideDetail({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}