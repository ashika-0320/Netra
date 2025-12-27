import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../frontend_models/location_model.dart';
import '../frontend_services/osm_service.dart';
import '../frontend_theme/app_theme.dart';
import '../frontend_widgets/location_card.dart';



class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final OSMService _osmService = OSMService();
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<LocationModel> _searchResults = [];
  bool _isListening = false;
  bool _isSearching = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );

    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _searchController.text = result.recognizedWords;
        });

        if (result.finalResult) {
          setState(() => _isListening = false);

          SemanticsService.announce(
            'Search query: ${result.recognizedWords}',
            TextDirection.ltr,
          );
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _searchLocations() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await _osmService.searchLocations(query, limit: 10);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      // ✅ THIS is where the "2nd code" goes:
      // show a visible message if no results are found
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No locations found for "$query"')),
        );

        SemanticsService.announce(
          'No locations found for $query',
          TextDirection.ltr,
        );
      } else {
        SemanticsService.announce(
          'Found ${results.length} locations',
          TextDirection.ltr,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSearching = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: ${e.toString()}')),
      );
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

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        leading: Semantics(
          label: 'Back button. Double tap to go back.',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Semantics(
                  label: 'Search location input field. Enter location to search.',
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Enter location',
                      hintText: 'Say or type location name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isListening
                          ? IconButton(
                        icon: const Icon(Icons.mic, color: Colors.red),
                        onPressed: _stopListening,
                        tooltip: 'Stop listening',
                      )
                          : IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: _startListening,
                        tooltip: 'Start voice input',
                      ),
                    ),
                    onSubmitted: (_) => _searchLocations(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Search button. Double tap to search for locations.',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: _isSearching ? null : _searchLocations,
                          icon: _isSearching
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.search),
                          label: Text(_isSearching ? 'Searching...' : 'Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      label: _isListening
                          ? 'Stop listening button. Double tap to stop voice input.'
                          : 'Start voice input button. Double tap to speak your search query.',
                      button: true,
                      child: ElevatedButton.icon(
                        onPressed: _isListening ? _stopListening : _startListening,
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        label: Text(_isListening ? 'Stop' : 'Voice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListening ? Colors.red[600] : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Listening... Speak now',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Search for locations',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use voice input or type to search for locations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return LocationCard(
                  location: _searchResults[index],
                  onTap: () => _showLocationDetails(_searchResults[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
