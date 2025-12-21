import 'package:get/get.dart';

class AuthController extends GetxController {
  // Google sign-in loading state
  final RxBool isGoogleSignInLoading = false.obs;

  void setGoogleSignInLoading(bool value) {
    isGoogleSignInLoading.value = value;
  }
}
