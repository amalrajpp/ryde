import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ryde/redirect.dart';
import 'package:ryde/config/firebase_options.dart';
import 'package:ryde/shared/services/location_permission.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp(
    name: 'parcelApp',
    options: const FirebaseOptions(
      apiKey: "AIzaSyBStAL2CRzLS14_ShD3gtpU8axRQaVOZVU",
      appId: "1:343169981401:web:7629528d73a42d183597c8",
      messagingSenderId: "343169981401",
      projectId: "parcel-delivery-system-5ff64",
      storageBucket: "parcel-delivery-system-5ff64.firebasestorage.app",
      // authDomain is optional but good to have if using web-based auth flows
      authDomain: "parcel-delivery-system-5ff64.firebaseapp.com",
    ),
  );
  requestLocationPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainPage(),
    );
  }
}
