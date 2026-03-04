class Detection {
  final String label;
  final String direction;     // left|centre|right
  final String depthBucket;   // very_close|close|ahead|far
  final double conf;

  Detection({
    required this.label,
    required this.direction,
    required this.depthBucket,
    required this.conf,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] as String,
      direction: json['direction'] as String,
      depthBucket: json['depth_bucket'] as String,
      conf: (json['conf'] as num).toDouble(),
    );
  }
}

class DetectResponse {
  final List<Detection> detections;

  DetectResponse({required this.detections});

  factory DetectResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['detections'] as List<dynamic>)
        .map((e) => Detection.fromJson(e as Map<String, dynamic>))
        .toList();
    return DetectResponse(detections: list);
  }
}