import 'package:flutter/material.dart';
import 'Maps/mapsNavigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Maps()),
            );
          },
        ),
      ),
    );
  }
}
