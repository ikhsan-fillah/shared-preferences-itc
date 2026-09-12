import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/user_binding.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Networking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Mendaftarkan UserBinding sebagai initial binding untuk Dependency Injection
      initialBinding: UserBinding(),
      home: const HomeView(),
    );
  }
}
