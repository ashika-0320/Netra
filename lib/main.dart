import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'frontend_pages/homepage.dart';
import 'frontend_theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Navigator',
      theme: AppTheme.lightTheme,
      home: HomePage(camera: camera),
      debugShowCheckedModeBanner: false,
    );
  }
}
