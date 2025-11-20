import 'package:flutter/material.dart';
import 'package:ryde/features/home/viewmodel/home_viewmodel.dart';
import '../widgets/home_header.dart';
import '../widgets/search_bar.dart';
import '../widgets/location_map.dart';
import '../widgets/recent_rides_card.dart';

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = HomeViewModel();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              HomeHeader(username: vm.username, onLogout: vm.logout),

              const SizedBox(height: 20),

              SearchBarWidget(controller: vm.searchController),

              const SizedBox(height: 25),

              const Text(
                "Your current location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              // const LocationMap(imagePath: "assets/images/dummy-map.jpg"),
              LocationMap(height: 240),

              const SizedBox(height: 25),

              const Text(
                "Recent Rides",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 15),

              const RecentRidesCard(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
