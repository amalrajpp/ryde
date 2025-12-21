import 'package:flutter/material.dart';

/// A simple ride summary screen shown after a booking is completed.
/// It expects either full booking data or a bookingId to fetch details.
class RideSummaryScreen extends StatelessWidget {
  final String? bookingId;
  final Map<String, dynamic>? bookingData;

  const RideSummaryScreen({super.key, this.bookingId, this.bookingData});

  @override
  Widget build(BuildContext context) {
    final data = bookingData ?? {};

    final route = (data['route'] as Map<String, dynamic>?) ?? {};
    final pickup = route['pickup_address'] ?? '';
    final dropoff = route['dropoff_address'] ?? '';
    final distance = (route['distance_km'] as num?)?.toDouble() ?? 0.0;
    final duration = (route['duration_mins'] as num?)?.toInt() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;

    final driver = (data['driver_details'] as Map<String, dynamic>?) ?? {};
    final driverName = driver['name'] ?? 'Your driver';
    final driverImage = driver['image'] ?? '';
    final vehicle = (data['vehicle_option'] as Map<String, dynamic>?) ?? {};
    final vehicleTitle =
        vehicle['display_title'] ?? vehicle['vehicle_type'] ?? '';
    final plate = driver['plate_number'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Summary'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Close summary and return to Home
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: driverImage.isNotEmpty
                        ? NetworkImage(driverImage) as ImageProvider
                        : const AssetImage(
                            'assets/images/avatar_placeholder.png',
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$vehicleTitle • $plate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(pickup)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dropoff)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${distance.toStringAsFixed(1)} km'),
                          Text('$duration mins'),
                          Text('₹${price.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // For now: go back to home
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement rating flow / receipt share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rating not implemented')),
                  );
                },
                icon: const Icon(Icons.star_border),
                label: const Text('Rate Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
