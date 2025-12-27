import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:geolocator/geolocator.dart';
import '../frontend_services/location_service.dart';
import '../frontend_theme/app_theme.dart';
import '../frontend_widgets/category_button.dart';
import 'locations_list_page.dart';
import 'search_location_page.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  String _locationAddress = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Automatically fetch location when page opens
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationAddress = '';
    });

    try {
      final position = await _locationService.getCurrentPosition();
      
      final address = await _locationService.getAddressFromCoordinates(
        position!.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _locationAddress = address;
        _isLoading = false;
      });

      // Announce only the location address to user via TalkBack
      Future.delayed(const Duration(milliseconds: 300), () {
        SemanticsService.announce(
          address,
          TextDirection.ltr,
        );
      });
    } catch (e) {
      setState(() {
        _locationAddress = 'Unable to get location';
        _isLoading = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showLocationDialog(Position position, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current Location'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Address:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(address),
                const SizedBox(height: 16),
                const Text(
                  'Coordinates:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
                const SizedBox(height: 8),
                Text('Accuracy: ${position.accuracy.toStringAsFixed(2)} meters'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCategory(String category) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationsListPage(category: category),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Mode'),
        leading: Semantics(
          label: 'Back button. Double tap to go back to home.',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Current Location and Search for Location Section
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Current Location Button
                  Expanded(
                    child: Semantics(
                      label: _locationAddress.isEmpty
                          ? 'Current Location. Loading.'
                          : 'Current Location. $_locationAddress. Double tap to view details.',
                      hint: 'Shows your current geographical position and address.',
                      button: true,
                      liveRegion: true,
                      child: InkWell(
                        onTap: () {
                          if (_currentPosition != null) {
                            _showLocationDialog(_currentPosition!, _locationAddress);
                          } else {
                            _getCurrentLocation();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.1),
                                AppTheme.primaryBlue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'CURRENT LOCATION',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryBlue,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: Center(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _locationAddress.isEmpty
                                                  ? 'Location not available'
                                                  : _locationAddress,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Search for Location Button
                  Expanded(
                    child: Semantics(
                      label: 'Search for Location. Double tap to search for a location.',
                      hint: 'Search and find a specific location or address.',
                      button: true,
                      child: InkWell(
                          onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const SearchLocationPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryGreen.withOpacity(0.1),
                                AppTheme.primaryGreen.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 24,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'SEARCH FOR LOCATION',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category Grid Section
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  CategoryButton(
                    label: 'HEALTH',
                    hint: 'Find nearby hospitals, clinics, and health services.',
                    onTap: () => _navigateToCategory('HEALTH'),
                  ),
                  CategoryButton(
                    label: 'TRANSPORT',
                    hint: 'Find nearby transportation services, bus stops, and taxi stands.',
                    onTap: () => _navigateToCategory('TRANSPORT'),
                  ),
                  CategoryButton(
                    label: 'BANK AND ATM',
                    hint: 'Find nearby banks and ATM machines.',
                    onTap: () => _navigateToCategory('BANK AND ATM'),
                  ),
                  CategoryButton(
                    label: 'FOOD',
                    hint: 'Find nearby restaurants, cafes, and food services.',
                    onTap: () => _navigateToCategory('FOOD'),
                  ),
                  CategoryButton(
                    label: 'LODGING',
                    hint: 'Find nearby hotels, hostels, and accommodation services.',
                    onTap: () => _navigateToCategory('LODGING'),
                  ),
                  CategoryButton(
                    label: 'STORE',
                    hint: 'Find nearby shops, stores, and shopping centers.',
                    onTap: () => _navigateToCategory('STORE'),
                  ),
                ],
              ),
            ),
          ),
          // Bottom spacing equivalent to one row of category buttons
          const SizedBox(
            height: 120,
          ),
        ],
      ),
    );
  }
}
