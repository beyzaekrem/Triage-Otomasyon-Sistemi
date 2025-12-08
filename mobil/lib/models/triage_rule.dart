class TriageRule {
  final int id;
  final String inputText;
  final List<String> symptoms;
  final int urgencyLevel;
  final String urgencyLabel;
  final String response;
  final String reasoning;

  TriageRule({
    required this.id,
    required this.inputText,
    required this.symptoms,
    required this.urgencyLevel,
    required this.urgencyLabel,
    required this.response,
    required this.reasoning,
  });

  factory TriageRule.fromJson(Map<String, dynamic> j) => TriageRule(
        id: j["id"] ?? 0,
        inputText: j["input_text"]?.toString() ?? "",
        symptoms: (j["symptoms"] as List?)?.map((e) => e.toString()).toList() ?? [],
        urgencyLevel: j["urgency_level"] ?? 3,
        urgencyLabel: j["urgency_label"]?.toString() ?? "Bilinmiyor",
        response: j["response"]?.toString() ?? "Açıklama bulunamadı.",
        reasoning: j["reasoning"]?.toString() ?? "",
      );
}
