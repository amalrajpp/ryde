import 'package:flutter/material.dart';
import 'package:ryde/features/home/viewmodel/home_viewmodel.dart';

import 'package:ryde/features/home/widgets/bottom_navbar.dart';

import '../widgets/home_header.dart';
import '../widgets/search_bar.dart';
import '../widgets/location_map.dart';
import '../widgets/recent_rides_card.dart';


class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeViewModel vm = HomeViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                HomeHeader(
                  username: vm.username,
                  onLogout: vm.logout,
                ),

                const SizedBox(height: 20),

                SearchBarWidget(controller: vm.searchController),

                const SizedBox(height: 25),

                const Text(
                  "Your current location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                const LocationMap(
                    imagePath: "assets/images/dummy-map.jpg"),

                const SizedBox(height: 25),

                const Text(
                  "Recent Rides",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 15),

                const RecentRidesCard(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: vm.navIndex,
        onTap: vm.onNavTap,
      ),
    );
  }
}