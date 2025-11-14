import 'package:flutter/material.dart';
class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps Navigation', style: TextStyle(fontSize: 50,),),
      ),
      body:Center(
        child: Text('maps page'),
      )
    );
  }
}
