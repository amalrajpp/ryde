import 'package:get/get.dart';
import '../models/account_user.dart';

class AccountController extends GetxController {
  Rx<AccountUser?> user = Rx<AccountUser?>(null);
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  void setUser(AccountUser? newUser) {
    user.value = newUser;
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setError(String value) {
    error.value = value;
  }
}
