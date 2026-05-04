import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/patient.dart';
import '../services/storage_service.dart';
import '../services/triage_service.dart';
import 'history_detail_page.dart';

class PatientCardPage extends StatefulWidget {
  const PatientCardPage({super.key});

  @override
  State<PatientCardPage> createState() => _PatientCardPageState();
}

class _PatientCardPageState extends State<PatientCardPage> {
  Patient? _p;
  Map<String, dynamic>? _history;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await StorageService.getAuthPatient();
    setState(() => _p = p);
    if (p != null) {
      _loadHistory(p.nationalId);
    }
  }

  Future<void> _loadHistory(String tc) async {
    setState(() => _loadingHistory = true);
    try {
      final history = await TriageService().fetchPatientHistory(tc);
      setState(() => _history = history);
    } catch (e) {
      debugPrint('Geçmiş yüklenemedi: $e');
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hasta Muayene Kartı', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _buildContent(_p!),
    );
  }

  Widget _buildContent(Patient p) {
    final status = (p.status ?? '').toUpperCase();
    final hasActiveSession = status.isNotEmpty && status != 'DONE';
    final isWaiting = status == 'TRIAGE_WAITING';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Current Status Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(p),
                  const Divider(height: 40, thickness: 1, color: Color(0xFFF1F5F9)),
                  if (isWaiting) 
                    _buildWaitingWarning()
                  else ...[
                    _buildPatientInfo(p, hasActiveSession),
                    const SizedBox(height: 24),
                    _buildSymptomsInfo(p),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // History Section
          _buildHistoryTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader(Patient p) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppColors.primary, size: 32),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('TC: ${p.nationalId}', style: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(Patient p, bool hasActiveSession) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DURUM ÖZETİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasActiveSession ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                hasActiveSession ? Icons.info_outline : Icons.history_toggle_off_rounded,
                color: hasActiveSession ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasActiveSession 
                    ? (p.statusMessage ?? p.status ?? 'Değerlendiriliyor') 
                    : 'Şu an aktif bir muayene süreciniz bulunmamaktadır.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasActiveSession ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsInfo(Patient p) {
    if (p.symptoms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BİLDİRİLEN ŞİKAYETLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.symptoms.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildWaitingWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.pending_actions_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            'Henüz Muayene Olmadınız',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Triyaj değerlendirmesi sonrası muayene kartınız burada güncellenecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    if (_loadingHistory) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final appointments = _history?['appointments'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text('MUAYENE GEÇMİŞİ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textTertiary, letterSpacing: 1.5)),
        ),
        if (appointments.isEmpty)
          _buildEmptyHistory()
        else
          ...appointments.map((a) => _buildTimelineItem(a)).toList(),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_outlined, color: AppColors.textTertiary.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 16),
          const Text('Kayıt Bulunmamaktadır', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic a) {
    final dateStr = a['createdAt']?.toString().split('T').first ?? '';
    final status = (a['status'] ?? 'Bilinmiyor').toString();
    final colorCode = (a['currentTriageColor'] ?? 'GRAY').toString().toUpperCase();
    
    Color statusColor = AppColors.textTertiary;
    if (colorCode == 'KIRMIZI') statusColor = Colors.red;
    else if (colorCode == 'SARI') statusColor = Colors.orange;
    else if (colorCode == 'YESIL') statusColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailPage(
                appointment: a,
                triageRecords: _history?['triageRecords'] ?? [],
                doctorNotes: _history?['doctorNotes'] ?? [],
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text(
          _getStatusLabel(status),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$dateStr • Sıra No: ${a['queueNumber'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING': return 'Bekliyor';
      case 'CALLED': return 'Muayeneye Çağrıldı';
      case 'IN_PROGRESS': return 'Muayene Ediliyor';
      case 'DONE': return 'Muayene Tamamlandı';
      case 'NO_SHOW': return 'Gelinmedi';
      default: return status;
    }
  }
}
