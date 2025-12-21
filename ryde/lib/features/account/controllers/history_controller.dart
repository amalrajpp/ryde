import 'package:get/get.dart';

class HistoryController extends GetxController {
  // Observables
  RxList<dynamic> rideHistory = <dynamic>[].obs;
  RxBool isLoading = false.obs;
  RxString error = ''.obs;
  RxInt selectedIndex = 0.obs; // 0: Completed, 1: Upcoming, 2: Cancelled

  @override
  void onInit() {
    super.onInit();
    // Load data automatically when the controller is created
    _loadDummyData();
  }

  void _loadDummyData() {
    if (rideHistory.isNotEmpty) return;

    isLoading.value = true;

    // Simulating API network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      rideHistory.assignAll(
        List.generate(
          8,
          (i) => {
            'pickup': 'Pickup ${i + 1} address',
            'drop': 'Drop ${i + 1} address',
            'date': '2025-12-${(i % 28) + 1}',
            // assigning dummy statuses to test tabs later if needed
            'status': i % 3 == 0
                ? 'completed'
                : (i % 3 == 1 ? 'upcoming' : 'cancelled'),
          },
        ),
      );
      isLoading.value = false;
    });
  }

  void setSelectedIndex(int index) {
    selectedIndex.value = index;
  }
}
