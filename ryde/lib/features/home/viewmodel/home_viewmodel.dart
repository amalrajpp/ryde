import 'package:flutter/material.dart';

class HomeViewModel {
  String username = "John";
  TextEditingController searchController = TextEditingController();
  int navIndex = 0;

  void onNavTap(int index) {
    navIndex = index;
    print("Selected nav index: $index");
  }

  void logout() {
    print("Logout clicked");
  }
}