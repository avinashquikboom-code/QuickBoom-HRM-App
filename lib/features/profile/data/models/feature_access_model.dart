class FeatureAccessModel {
  final String name;
  final bool active;
  final String? reason;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? validFromTime;
  final String? validToTime;

  FeatureAccessModel({
    required this.name,
    required this.active,
    this.reason,
    this.validFrom,
    this.validTo,
    this.validFromTime,
    this.validToTime,
  });

  factory FeatureAccessModel.fromJson(Map<String, dynamic> json) {
    return FeatureAccessModel(
      name: json['name'] ?? '',
      active: json['active'] ?? false,
      reason: json['reason'],
      validFrom: json['validFrom'] != null ? DateTime.tryParse(json['validFrom']) : null,
      validTo: json['validTo'] != null ? DateTime.tryParse(json['validTo']) : null,
      validFromTime: json['validFromTime'],
      validToTime: json['validToTime'],
    );
  }
}
