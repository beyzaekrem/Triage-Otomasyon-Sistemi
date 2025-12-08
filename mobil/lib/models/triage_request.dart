class TriageRequest {
  final String fullName;
  final String nationalId;
  final List<String> symptoms;

  const TriageRequest({
    required this.fullName,
    required this.nationalId,
    required this.symptoms,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'tc': nationalId,
        'symptoms': symptoms,
      };
}

