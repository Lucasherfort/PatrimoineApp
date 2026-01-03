import 'package:flutter/material.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const PatrimoineApp());
}

class PatrimoineApp extends StatelessWidget {
  const PatrimoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrimoine App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // ✅ Page d’accueil au lancement
    );
  }
}

