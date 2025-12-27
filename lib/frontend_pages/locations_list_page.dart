import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../frontend_models/location_model.dart';
import '../frontend_services/location_service.dart';

import '../frontend_theme/app_theme.dart';
import '../frontend_widgets/location_card.dart';


class LocationsListPage extends StatefulWidget {
  final String category;

  const LocationsListPage({
    super.key,
    required this.category,
  });

  @override
  State<LocationsListPage> createState() => _LocationsListPageState();
}

class _LocationsListPageState extends State<LocationsListPage> {
  final LocationService _locationService = LocationService();
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current position
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Get nearby places
      final places = await _locationService.getNearbyPlaces(
        latitude: position!.latitude,
        longitude: position.longitude,
        category: widget.category,
        limit: 6,
        radius: 2000, // 2km radius
      );

      setState(() {
        _locations = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showLocationDetails(LocationModel location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(location.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.address != null) ...[
                  const Text(
                    'Address:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(location.address!),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Coordinates:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
                if (location.distance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Distance: ${location.distance!.toStringAsFixed(0)} meters',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryTitle() {
    switch (widget.category.toUpperCase()) {
      case 'TRANSPORT':
        return 'Nearby Transport';
      case 'HEALTH':
        return 'Nearby Health Services';
      case 'BANK AND ATM':
        return 'Nearby Banks & ATMs';
      case 'FOOD':
        return 'Nearby Restaurants';
      case 'LODGING':
        return 'Nearby Hotels';
      case 'STORE':
        return 'Nearby Stores';
      default:
        return 'Nearby Places';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
        leading: Semantics(
          label: 'Back button. Double tap to go back.',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          Semantics(
            label: 'Refresh locations. Double tap to reload.',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchLocations,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchLocations,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _locations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No locations found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No ${widget.category.toLowerCase()} found nearby.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _fetchLocations,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        return LocationCard(
                          location: _locations[index],
                          onTap: () => _showLocationDetails(_locations[index]),
                        );
                      },
                    ),
    );
  }
}

