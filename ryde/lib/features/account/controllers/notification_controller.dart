import 'package:get/get.dart';

class NotificationController extends GetxController {
  RxList<dynamic> notifications = <dynamic>[].obs;
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  void setNotifications(List<dynamic> notifs) {
    notifications.value = notifs;
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setError(String value) {
    error.value = value;
  }
}
