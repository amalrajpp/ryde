import 'package:flutter/material.dart';

class CarImage extends StatelessWidget {
  const CarImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage("assets/images/dummy-map.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
