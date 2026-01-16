import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MapsNavigation extends StatefulWidget {
  const MapsNavigation({super.key});

  @override
  State<MapsNavigation> createState() => _MapsNavigationState();
}

class _MapsNavigationState extends State<MapsNavigation> {
  LatLng? _currentPosition;
  List<LatLng> _routePoints = []; // New: Stores the polyline for the route
  Marker? _searchMarker;
  List<String> _directions = [];
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions =[];
  List<LatLng> _maneuverPoints = [];
  int _currentStepIndex = 0;

  String? _currentInstruction = "";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    var permission = await Permission.location.request();
    if (!permission.isGranted || !mounted) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (!mounted) return;

    _mapController.move(_currentPosition!, 15);
    _startLiveNavigation();
  }

  void _startLiveNavigation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // updates every 2 meters
      ),
    ).listen((pos) {
      LatLng userLatLng = LatLng(pos.latitude, pos.longitude);
      _checkNavigationProgress(userLatLng);

      if (mounted) {
        setState(() {
          _currentPosition = userLatLng;
        });
      }
    });
  }

  void _checkNavigationProgress(LatLng current) {
    if (_maneuverPoints.isEmpty || _currentStepIndex >= _maneuverPoints.length) {
      return;
    }

    final Distance distance = Distance();
    double dist = distance(current, _maneuverPoints[_currentStepIndex]);

    // Always update the countdown
    _announceDistance(dist);

    // When you reach the turn, go to next step
    if (dist < 8) {
      _currentStepIndex++;

      if (_currentStepIndex < _directions.length) {
        // Immediately show next instruction
        _currentInstruction = _directions[_currentStepIndex];
      } else {
        _currentInstruction = "Navigation complete";
      }

      setState(() {});
    }
  }


  void _announceDistance(double meters) {
    if (_currentStepIndex >= _directions.length) return;

    String baseInstruction = _directions[_currentStepIndex];

    // When very close
    if (meters <= 8) {
      setState(() {
        _currentInstruction = "$baseInstruction now";
      });
      return;
    }

    // Countdown text
    setState(() {
      _currentInstruction = "$baseInstruction in ${meters.toInt()} m";
    });
  }


  String _readableDirection(maneuver) {
    final type = maneuver['type'] ?? '';
    final modifier = maneuver['modifier'] ?? '';

    if (type == 'turn') {
      if (modifier == 'left') return 'Turn left';
      if (modifier == 'right') return 'Turn right';
      if (modifier == 'slight left') return 'Slight left';
      if (modifier == 'slight right') return 'Slight right';
      if (modifier == 'sharp left') return 'Sharp left';
      if (modifier == 'sharp right') return 'Sharp right';
    }

    if (type == 'depart') return 'Head Straight';
    if (type == 'arrive') return 'Arrived at destination';
    if (type == 'merge') return 'Merge';
    if (type == 'roundabout') return 'Enter roundabout';

    return 'Continue straight';
  }



  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&q=$query&addressdetails=1&limit=5");

    final response = await http.get(
      url,
      headers: {
        "User-Agent": "Netra/1.0",
        "Accept-Language": "en",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (mounted) {
        setState(() {
          _suggestions = data;
        });
      }
    }
  }

  void _searchLocationFromButton() {
    if (_suggestions.isNotEmpty) {
      final item = _suggestions[0];
      _searchLocation(item["display_name"], item["lat"], item["lon"]);
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);

    // Simple zoom calculation: approximate
    double latDiff = maxLat - minLat;
    double lonDiff = maxLon - minLon;
    double maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
    double zoom = 15 - (maxDiff * 10); // tweak factor 10 to fit route better
    if (zoom < 3) zoom = 3; // minimum zoom
    if (zoom > 18) zoom = 18; // max zoom

    _mapController.move(center, zoom);
  }




  Future<void> _searchLocation(String displayName, String lat, String lon) async {
    final destination = LatLng(double.parse(lat), double.parse(lon));

    setState(() {
      _searchMarker = Marker(
        point: destination,
        width: 60,
        height: 60,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      );
      _searchController.text = displayName;
      _routePoints = [];
      _directions = [];
      _maneuverPoints = [];
      _suggestions = [];
      _currentStepIndex = 0;
      _currentInstruction = "";
    });

    if (_currentPosition == null) return;

    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${_currentPosition!.longitude},${_currentPosition!.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson&steps=true');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if ((data['routes'] as List).isNotEmpty) {
        final routeCoords = data['routes'][0]['geometry']['coordinates'] as List;
        final steps = data['routes'][0]['legs'][0]['steps'] as List;

        // Build polyline
        final routePoints = routeCoords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();

        // Extract directions with distances
        final directionsList = steps.map<String>((step) {
          final instruction = _readableDirection(step['maneuver']);
          final distance = step['distance']?.toDouble() ?? 0;
          final distMeters = distance.toStringAsFixed(0);

          return "$instruction — $distMeters m";
        }).toList();



        // Extract maneuver points
        final maneuverList = steps.map<LatLng>((step) {
          final maneuver = step['maneuver'];
          double lat = maneuver['location'][1].toDouble();
          double lon = maneuver['location'][0].toDouble();
          return LatLng(lat, lon);
        }).toList();

        setState(() {
          _routePoints = routePoints;
          _directions = directionsList;
          _maneuverPoints = maneuverList;
        });

        _fitMapToRoute(routePoints);
      }
    }
  }

  void _startTurnByTurn() {
    if (_directions.isEmpty) return;

    setState(() {
      _currentStepIndex = 0;
      _currentInstruction = _directions[0];
    });
  }



  void _showDirections() {
    if (_directions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _directions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text('${index + 1}'),
              title: Text(_directions[index]),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {

    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Maps Page')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps Page'),
      ),
      body: Stack(
        children:[
          FlutterMap(
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
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                ],
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
                  if(_searchMarker!=null) _searchMarker!,
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
    Positioned(
    top: 10,
    left: 10,
    right: 10,
    child: Column(
      mainAxisSize: MainAxisSize.min,
    children: [
    Row(
      children: [
        Expanded(
          child: Card(
          child: TextField(
          controller: _searchController,
          onChanged: _fetchSuggestions,
          decoration: const InputDecoration(
          hintText: "Search location",
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          border: InputBorder.none,
          ),
          ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _searchLocationFromButton,
          child: const Text("Search"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _startTurnByTurn,
          child: const Text("Start"
              ""),
        ),
      ],
    ),

    // ----------------------
    // AUTOCOMPLETE DROPDOWN
    // ----------------------
      if (_suggestions.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Card(
            margin: const EdgeInsets.only(top: 5),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  title: Text(item["display_name"] ?? ""),
                  onTap: () {
                    _searchLocation(
                        item["display_name"], item["lat"], item["lon"]);
                  },
                );
              },
            ),
          ),
        ),

        ]
    ),
    ),
          // Floating button to show all directions
          Positioned(
            bottom: 100,
            left: 20,
            child: FloatingActionButton.extended(
              onPressed: _directions.isEmpty ? null : _showDirections,
              backgroundColor: Colors.white,
              label: const Text(
                "View Directions",
                style: TextStyle(color: Colors.black),
              ),
              icon: const Icon(Icons.list, color: Colors.black),
            ),
          ),

          if (_currentInstruction != null && _currentInstruction!.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentInstruction!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
],
      ),
    );
  }
}
