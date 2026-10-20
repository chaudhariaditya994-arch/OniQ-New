class StorageBatch {
  final String id;
  final String userEmail;
  final String name;
  final String structureType;
  final String variety;
  final double quantityQuintals;
  final String startDate;
  final String location;
  final String deviceId;
  final String notes;
  final bool isActive;
  final Map<String, dynamic>? latestReading;
  final Map<String, dynamic>? latestRisk;

  StorageBatch({
    required this.id,
    required this.userEmail,
    required this.name,
    required this.structureType,
    required this.variety,
    required this.quantityQuintals,
    required this.startDate,
    required this.location,
    required this.deviceId,
    this.notes = '',
    this.isActive = true,
    this.latestReading,
    this.latestRisk,
  });

  factory StorageBatch.fromJson(Map<String, dynamic> json) {
    return StorageBatch(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userEmail: json['user_email'] ?? '',
      name: json['name'] ?? 'Storage Lot',
      structureType: json['structure_type'] ?? 'Traditional Chawl',
      variety: json['variety'] ?? 'Garwa',
      quantityQuintals: (json['quantity_quintals'] as num?)?.toDouble() ?? 50.0,
      startDate: json['start_date'] ?? '',
      location: json['location'] ?? 'Nashik, Maharashtra',
      deviceId: json['device_id'] ?? 'esp32-node-01',
      notes: json['notes'] ?? '',
      isActive: json['is_active'] ?? true,
      latestReading: json['latest_reading'] as Map<String, dynamic>?,
      latestRisk: json['latest_risk'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageBatch && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StorageReading {
  final String deviceId;
  final String? batchId;
  final String timestamp;
  final double temperature;
  final double humidity;
  final double mq135Raw;
  final double mq136Raw;
  final double? batteryPct;
  final int? rssi;
  final double? riskScore;
  final String? riskLevel;

  StorageReading({
    required this.deviceId,
    this.batchId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.mq135Raw,
    required this.mq136Raw,
    this.batteryPct,
    this.rssi,
    this.riskScore,
    this.riskLevel,
  });

  factory StorageReading.fromJson(Map<String, dynamic> json) {
    return StorageReading(
      deviceId: json['device_id'] ?? '',
      batchId: json['batch_id'],
      timestamp: json['timestamp'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 27.5,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 65.0,
      mq135Raw: (json['mq135_raw'] as num?)?.toDouble() ?? 600.0,
      mq136Raw: (json['mq136_raw'] as num?)?.toDouble() ?? 350.0,
      batteryPct: (json['battery_pct'] as num?)?.toDouble(),
      rssi: json['rssi'] as int?,
      riskScore: (json['risk_score'] as num?)?.toDouble(),
      riskLevel: json['risk_level'],
    );
  }
}

class StorageRiskAssessment {
  final double riskScore;
  final String riskLevel;
  final String statusColor;
  final String temperatureStatus;
  final String humidityStatus;
  final String airQualityStatus;
  final String sulfurGasStatus;
  final String primaryConcern;
  final List<String> recommendations;
  final String evaluatedAt;

  StorageRiskAssessment({
    required this.riskScore,
    required this.riskLevel,
    required this.statusColor,
    required this.temperatureStatus,
    required this.humidityStatus,
    required this.airQualityStatus,
    required this.sulfurGasStatus,
    required this.primaryConcern,
    required this.recommendations,
    required this.evaluatedAt,
  });

  factory StorageRiskAssessment.fromJson(Map<String, dynamic> json) {
    return StorageRiskAssessment(
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 10.0,
      riskLevel: json['risk_level'] ?? 'Low',
      statusColor: json['status_color'] ?? 'green',
      temperatureStatus: json['temperature_status'] ?? '',
      humidityStatus: json['humidity_status'] ?? '',
      airQualityStatus: json['air_quality_status'] ?? '',
      sulfurGasStatus: json['sulfur_gas_status'] ?? '',
      primaryConcern: json['primary_concern'] ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evaluatedAt: json['evaluated_at'] ?? '',
    );
  }
}

class StorageAdvisory {
  final String batchId;
  final String batchName;
  final StorageRiskAssessment riskAssessment;
  final String advisoryText;
  final List<String> actionChecklist;
  final String generatedAt;
  final String provider;

  StorageAdvisory({
    required this.batchId,
    required this.batchName,
    required this.riskAssessment,
    required this.advisoryText,
    required this.actionChecklist,
    required this.generatedAt,
    required this.provider,
  });

  factory StorageAdvisory.fromJson(Map<String, dynamic> json) {
    return StorageAdvisory(
      batchId: json['batch_id'] ?? '',
      batchName: json['batch_name'] ?? '',
      riskAssessment: StorageRiskAssessment.fromJson(
          json['risk_assessment'] as Map<String, dynamic>? ?? {}),
      advisoryText: json['advisory_text'] ?? '',
      actionChecklist: (json['action_checklist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generated_at'] ?? '',
      provider: json['provider'] ?? 'oniq-engine',
    );
  }
}
