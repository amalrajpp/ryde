import 'package:geolocator/geolocator.dart';

Future<void> requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location service is enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return;
  }

  // Check permission status
  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Location permission denied");
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print("Location permission denied forever");
    await Geolocator.openAppSettings();
    return;
  }

  // Permission granted: get location
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  print(position);
}
