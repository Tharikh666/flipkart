import 'package:firebase_core/firebase_core.dart';
import 'package:flipkart/screens/navigation_bar.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyBwB52UFvegZXTldXwJTAHroFnJaJUR-Bo',
    authDomain: 'flipkart-6d2f7.firebaseapp.com',
    projectId: 'flipkart-6d2f7',
    storageBucket: 'flipkart-6d2f7.appspot.com',
    messagingSenderId: '241106067243',
    appId: '1:241106067243:android:3c4fcdf0a141f0f80b2f6e',
  );

  await Firebase.initializeApp(options: firebaseOptions);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Flipkart(),
    ),
  );

  runApp(const Flipkart());
}

class Flipkart extends StatelessWidget {
  const Flipkart({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Navigate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
