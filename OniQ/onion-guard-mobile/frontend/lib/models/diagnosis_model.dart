class DiagnosisModel {
  final int? id;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final String timestamp;
  final bool synced;

  DiagnosisModel({
    this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.timestamp,
    this.synced = false,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'],
      imagePath: json['image_path'] ?? '',
      diseaseName: json['disease'] ?? json['disease_name'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      synced: json['synced'] == 1 || json['synced'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'image_path': imagePath,
        'disease_name': diseaseName,
        'confidence': confidence,
        'timestamp': timestamp,
        'synced': synced ? 1 : 0,
      };

  String get severityLevel {
    if (diseaseName == 'Healthy') return 'none';
    if (confidence > 90) return 'critical';
    if (confidence > 70) return 'high';
    return 'moderate';
  }
}
