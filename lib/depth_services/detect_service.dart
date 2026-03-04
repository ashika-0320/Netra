import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'detect_json.dart';

class DetectService {
  static const String _baseUrl = 'http://192.168.1.71:8000';

  // PNG bytes (keep for UI)
  static Future<Uint8List> detectWithDepth(Uint8List imageBytes) async {
    final uri = Uri.parse('$_baseUrl/detect-depth');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'frame.jpg',
      ));

    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();

    if (streamed.statusCode == 200) {
      return bytes;
    } else {
      final msg = String.fromCharCodes(bytes);
      throw Exception('Detect API error: ${streamed.statusCode} $msg');
    }
  }

  // JSON (for speech)
  static Future<DetectResponse> detectWithDepthJson(Uint8List imageBytes) async {
    final uri = Uri.parse('$_baseUrl/detect-depth-json');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'frame.jpg',
      ));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('Detect JSON API error: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    return DetectResponse.fromJson(jsonMap);
  }
}