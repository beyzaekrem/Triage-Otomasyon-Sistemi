class QueueStatus {
  final int? queueNumber;
  final int? estimatedWaitMinutes;
  final String? status;

  const QueueStatus({
    this.queueNumber,
    this.estimatedWaitMinutes,
    this.status,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) => QueueStatus(
        queueNumber: _asInt(json['queueNumber'] ?? json['queue_number']),
        estimatedWaitMinutes:
            _asInt(json['estimatedWait'] ?? json['estimated_wait_minutes']),
        status: json['status']?.toString(),
      );

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

