import 'package:flutter/material.dart';
import 'package:ryde/features/screen/ride_booking.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;

  const SearchBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RideBookingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Where do you want to go?",
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
