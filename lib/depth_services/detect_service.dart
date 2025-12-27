import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DetectService {
  static const String _baseUrl = 'http://192.168.1.71:8000';

  // Returns PNG bytes from the API (annotated YOLO + depth text)
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
      return bytes; // PNG bytes
    } else {
      final msg = String.fromCharCodes(bytes);
      throw Exception('Detect API error: ${streamed.statusCode} $msg');
    }
  }
}
