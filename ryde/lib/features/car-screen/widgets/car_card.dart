import 'package:flutter/material.dart';
import 'package:ryde/features/car-screen/widgets/car_details.dart';

import 'car_image.dart';

class CarCard extends StatelessWidget {
  const CarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW (Image + Pickup/Drop)
          Row(
            children: [
              const CarImage(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CarDetailRow(
                      icon: Icons.navigation,
                      
                      text: "1901 Thornridge Cir. Shiloh",
                      
                    ),
                    SizedBox(height: 6),
                    CarDetailRow(
                      icon: Icons.location_on_outlined,
                      text: "4140 Parker Rd. Allentown",
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// DETAILS SECTION
          const CarDetailRow(
            icon: Icons.calendar_today,
            title: "Date & Time",
            text: "16 July 2025, 10:30 PM",
            
          ),
          const CarDetailRow(
            icon: Icons.person,
            title: "Driver",
            text: "Jane Cooper",
          ),
          const CarDetailRow(
            icon: Icons.airline_seat_recline_extra,
            title: "Car Seats",
            text: "4",
          ),
          CarDetailRow(
            icon: Icons.payment,
            title: "Payment Status",
            text: "Paid",
            textColor: Colors.green[700],
          ),
        ],
      ),
    );
  }
}
