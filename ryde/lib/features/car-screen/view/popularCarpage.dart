import 'package:flutter/material.dart';
import 'package:ryde/features/car-screen/widgets/car_card.dart';

class PopularCarsPage extends StatelessWidget {
  const PopularCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Popular Car",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CarCard(),
          SizedBox(height: 20),
          CarCard(),
        ],
      ),
    );
  }
}
