class Patient {
  final String fullName;
  final String nationalId;
  final List<String> symptoms;
  final int queueNumber;        // statik/örnek
  final String urgencyLabel;    // ACIL / ONCELIKLI / NORMAL
  final int urgencyLevel;       // 1 ACIL ... 3 NORMAL
  final String responseText;    // hastaya gösterilecek açıklama
  final DateTime? createdAt;    // kayıt zamanı

  Patient({
    required this.fullName,
    required this.nationalId,
    required this.symptoms,
    required this.queueNumber,
    required this.urgencyLabel,
    required this.urgencyLevel,
    required this.responseText,
    this.createdAt,
  });

  /// Create a copy with updated fields
  Patient copyWith({
    String? fullName,
    String? nationalId,
    List<String>? symptoms,
    int? queueNumber,
    String? urgencyLabel,
    int? urgencyLevel,
    String? responseText,
    DateTime? createdAt,
  }) {
    return Patient(
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      symptoms: symptoms ?? this.symptoms,
      queueNumber: queueNumber ?? this.queueNumber,
      urgencyLabel: urgencyLabel ?? this.urgencyLabel,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      responseText: responseText ?? this.responseText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        "fullName": fullName,
        "nationalId": nationalId,
        "symptoms": symptoms,
        "queueNumber": queueNumber,
        "urgencyLabel": urgencyLabel,
        "urgencyLevel": urgencyLevel,
        "responseText": responseText,
        "createdAt": createdAt?.toIso8601String(),
      };

  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
        fullName: j["fullName"] as String? ?? "",
        nationalId: j["nationalId"] as String? ?? "",
        symptoms: List<String>.from(j["symptoms"] as List? ?? []),
        queueNumber: j["queueNumber"] as int? ?? 0,
        urgencyLabel: j["urgencyLabel"] as String? ?? "BELIRSIZ",
        urgencyLevel: j["urgencyLevel"] as int? ?? 3,
        responseText: j["responseText"] as String? ?? "",
        createdAt: j["createdAt"] != null 
            ? DateTime.tryParse(j["createdAt"] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          nationalId == other.nationalId &&
          queueNumber == other.queueNumber;

  @override
  int get hashCode => fullName.hashCode ^ nationalId.hashCode ^ queueNumber.hashCode;
}
