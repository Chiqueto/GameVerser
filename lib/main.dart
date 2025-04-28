import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAQBq0MbkwL6Sx5kkEQPiGNwAx3rdOP5dY",
        authDomain: "superhero-ca382.firebaseapp.com",
        projectId: "superhero-ca382",
        storageBucket: "superhero-ca382.appspot.com",
        messagingSenderId: "864149595642",
        appId: "1:864149595642:web:b2a45ff65aad09c6e83043",
      ),
    );
    print("✅ Firebase OK!");
  } catch (e) {
    print("🔥 Firebase error: $e");
  }

  await dotenv.load(fileName: '.env');
  print('Variáveis carregadas:');
  print('Client ID: ${dotenv.env['IGDB_CLIENT_ID'] != null ? "OK" : "NULO"}');
  print('Client Secrete: ${dotenv.env['IGDB_CLIENT_SECRET']}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperHero App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
