// Sentinel object to distinguish "not provided" from explicit null in copyWith
const _absent = Object();

class Patient {
  final String fullName;
  final String nationalId;
  final List<String> symptoms;
  final int queueNumber;
  final String urgencyLabel;    // ACIL / ONCELIKLI / NORMAL
  final int urgencyLevel;       // 1 ACIL ... 3 NORMAL
  final String responseText;    // hastaya gösterilecek açıklama
  final DateTime? createdAt;    // kayıt zamanı
  final int? estimatedWaitMinutes;
  final String? status;
  final String? statusMessage;
  final int? birthYear;
  final String? gender; // E / K
  final String? colorCode;

  Patient({
    required this.fullName,
    required this.nationalId,
    required this.symptoms,
    required this.queueNumber,
    required this.urgencyLabel,
    required this.urgencyLevel,
    required this.responseText,
    this.createdAt,
    this.estimatedWaitMinutes,
    this.status,
    this.statusMessage,
    this.birthYear,
    this.gender,
    this.colorCode,
  });

  /// Create a copy with updated fields.
  /// Pass explicit `null` to CLEAR a nullable field (e.g. colorCode: null).
  Patient copyWith({
    String? fullName,
    String? nationalId,
    List<String>? symptoms,
    int? queueNumber,
    String? urgencyLabel,
    int? urgencyLevel,
    String? responseText,
    Object? createdAt = _absent,
    Object? estimatedWaitMinutes = _absent,
    Object? status = _absent,
    Object? statusMessage = _absent,
    Object? birthYear = _absent,
    Object? gender = _absent,
    Object? colorCode = _absent,
  }) {
    return Patient(
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      symptoms: symptoms ?? this.symptoms,
      queueNumber: queueNumber ?? this.queueNumber,
      urgencyLabel: urgencyLabel ?? this.urgencyLabel,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      responseText: responseText ?? this.responseText,
      createdAt: identical(createdAt, _absent) ? this.createdAt : createdAt as DateTime?,
      estimatedWaitMinutes: identical(estimatedWaitMinutes, _absent) ? this.estimatedWaitMinutes : estimatedWaitMinutes as int?,
      status: identical(status, _absent) ? this.status : status as String?,
      statusMessage: identical(statusMessage, _absent) ? this.statusMessage : statusMessage as String?,
      birthYear: identical(birthYear, _absent) ? this.birthYear : birthYear as int?,
      gender: identical(gender, _absent) ? this.gender : gender as String?,
      colorCode: identical(colorCode, _absent) ? this.colorCode : colorCode as String?,
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
        "estimatedWaitMinutes": estimatedWaitMinutes,
        "status": status,
        "statusMessage": statusMessage,
        "birthYear": birthYear,
        "gender": gender,
        "colorCode": colorCode,
      };

  factory Patient.fromJson(Map<String, dynamic> j) {
    // Backend returns 'name' but we use 'fullName' in the model
    final name = j["name"] as String? ?? j["fullName"] as String? ?? "";
    final tc = j["tc"] as String? ?? j["nationalId"] as String? ?? "";
    
    // Handle symptoms - could be a list or CSV string
    List<String> symptomsList = [];
    if (j["symptoms"] != null) {
      if (j["symptoms"] is List) {
        symptomsList = List<String>.from(j["symptoms"]);
      } else if (j["symptoms"] is String) {
        symptomsList = (j["symptoms"] as String).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }
    
    return Patient(
      fullName: name,
      nationalId: tc,
      symptoms: symptomsList,
        queueNumber: j["queueNumber"] as int? ?? 0,
        urgencyLabel: j["urgencyLabel"] as String? ?? "BELIRSIZ",
        urgencyLevel: j["urgencyLevel"] as int? ?? 3,
        responseText: j["responseText"] as String? ?? "",
        createdAt: j["createdAt"] != null 
            ? DateTime.tryParse(j["createdAt"] as String)
            : null,
      estimatedWaitMinutes: j["estimatedWaitMinutes"] as int?,
      status: j["status"] as String?,
      statusMessage: j["statusMessage"] as String?,
      birthYear: j["birthYear"] as int?,
      gender: j["gender"] as String?,
      colorCode: j["colorCode"] as String?,
      );
  }

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
