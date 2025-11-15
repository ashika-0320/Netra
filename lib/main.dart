import 'package:flutter/material.dart';
import 'Maps/mapsNavigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NETRA')),
      body: Center(
        child: IconButton(
          icon: Icon(Icons.my_location),
          onPressed: () {
            print('pressed');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapsNavigation()),
            );
          },
        ),
      ),
    );
  }
}
