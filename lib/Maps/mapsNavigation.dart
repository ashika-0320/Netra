import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapsNavigation extends StatefulWidget {
  const MapsNavigation({super.key});

  @override
  State<MapsNavigation> createState() => _MapsNavigationState();
}

class _MapsNavigationState extends State<MapsNavigation> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async{
    var permission = await Permission.location.request();
    if (!permission.isGranted) return;

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Move map to current location
    _mapController.move(_currentPosition!, 15);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps Page'),
      ),
      body: SizedBox.expand(
        child: FlutterMap(
          options:MapOptions(
            initialCenter: _currentPosition!,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: _currentPosition!,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
