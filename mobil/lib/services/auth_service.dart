import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/patient.dart';

class AuthService {
  AuthService._();
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;

  Future<Patient> register(Patient p) async {
    try {
      final res = await ApiClient().client.post('/mobile/patient/register', data: {
        'tc': p.nationalId,
        'fullName': p.fullName,
        if (p.birthYear != null) 'birthYear': p.birthYear,
        if (p.gender != null && p.gender!.isNotEmpty) 'gender': p.gender,
      });
      final data = res.data as Map<String, dynamic>;
      final patientData = data['patient'] as Map<String, dynamic>;
      return Patient.fromJson(patientData);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 
          e.message ?? 
          'Kayıt başarısız';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Kayıt başarısız: $e');
    }
  }

  Future<Patient> login({required String tc, required String name}) async {
    try {
      final res = await ApiClient().client.post('/mobile/patient/login', data: {
        'tc': tc,
        'name': name,
      });
      final data = res.data as Map<String, dynamic>;
      final patientData = data['patient'] as Map<String, dynamic>;
      return Patient.fromJson(patientData);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 
          e.message ?? 
          'Giriş başarısız';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Giriş başarısız: $e');
    }
  }
}

