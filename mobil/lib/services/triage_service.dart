import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/queue_status.dart';
import '../models/triage_request.dart';
import '../models/triage_response.dart';
import '../models/triage_rule.dart';
import 'api_client.dart';

class TriageService {
  static final TriageService _i = TriageService._();
  TriageService._();
  factory TriageService() => _i;

  List<TriageRule> _rules = [];
  bool _loaded = false;
  bool _loading = false;

  /// Submit triage to backend. Falls back to local rules if backend fails due to connection.
  Future<TriageResponse?> submitTriage(TriageRequest request) async {
    try {
      final res = await ApiClient()
          .client
          .post('/mobile/triage', data: request.toJson());

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return TriageResponse.fromJson(data);
      }
      if (data is Map) {
        return TriageResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      // Check if it's a network error (offline) - use local fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        debugPrint('Backend erişilemiyor, yerel tahmin kullanılıyor...');
        return _localFallback(request);
      }

      // Server responded with error (e.g. 404, 409 conflict, 500)
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Triage isteği başarısız';
      
      throw Exception(msg);
    } catch (e) {
      debugPrint('Beklenmeyen triage hatası: $e');
      rethrow;
    }
  }

  /// Local fallback when backend is unreachable
  Future<TriageResponse?> _localFallback(TriageRequest request) async {
    final rule = await matchBySymptoms(request.symptoms);
    if (rule == null) return null;

    return TriageResponse(
      message: 'Çevrimdışı tahmin: Lütfen internet bağlantınızı kontrol edin.',
      urgencyLevel: rule.urgencyLevel,
      urgencyLabel: rule.urgencyLabel,
      responseText: rule.response,
      reasoning: rule.reasoning,
      queueNumber: null,
      estimatedWaitMinutes: null,
      waitingAhead: 0,
      status: 'OFFLINE',
      patientName: null,
    );
  }

  /// Fetch queue status for a patient tc.
  Future<QueueStatus?> fetchQueueStatus(String tc) async {
    if (tc.isEmpty) return null;
    try {
      final res =
          await ApiClient().client.get('/appointments/mobile/queue/$tc');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return QueueStatus.fromJson(data);
      }
      if (data is Map) {
        return QueueStatus.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return QueueStatus(found: false, message: 'Aktif randevu bulunamadı');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/triage_rules.json');
      final List<dynamic> list = json.decode(jsonStr);
      _rules = list.map((e) => TriageRule.fromJson(e)).toList();
      _loaded = true;
    } catch (e) {
      debugPrint('Rules yüklenemedi: $e');
    } finally {
      _loading = false;
    }
  }

  Future<TriageRule?> matchBySymptoms(List<String> symptoms) async {
    await _ensureLoaded();
    if (symptoms.isEmpty) return null;

    TriageRule? bestMatch;
    int maxMatch = 0;

    for (final rule in _rules) {
      int count = 0;
      for (final s in symptoms) {
        if (rule.symptoms.any((rs) => rs.toLowerCase() == s.toLowerCase())) {
          count++;
        }
      }
      if (count > maxMatch) {
        maxMatch = count;
        bestMatch = rule;
      }
    }
    return bestMatch;
  }

  Future<Map<String, dynamic>?> fetchPatientHistory(String tc) async {
    if (tc.isEmpty) return null;
    try {
      final res = await ApiClient().client.get('/appointments/history/$tc');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('History fetch error: $e');
      return null;
    }
  }
}
