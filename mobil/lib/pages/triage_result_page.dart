import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/storage_service.dart';
import '../services/triage_service.dart';
import '../models/patient.dart';
import '../utils/urgency_helper.dart';
import 'patient_card_page.dart';

class TriageResultPage extends StatefulWidget {
  const TriageResultPage({super.key});

  @override
  State<TriageResultPage> createState() => _TriageResultPageState();
}

class _TriageResultPageState extends State<TriageResultPage> {
  Patient? _p;
  bool _refreshing = false;
  bool _notifyOnUpdate = true;
  int? _lastWait;
  String? _lastStatusText;

  bool get _isFinished => (_p?.status ?? '').toUpperCase() == 'DONE';
  bool get _isCalled => (_p?.status ?? '').toUpperCase() == 'CALLED';
  bool get _isWaitingForTriage => (_p?.status ?? '').toUpperCase() == 'TRIAGE_WAITING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Patient? p = await StorageService.getAuthPatient();
    final notifyPref = await StorageService.getNotifyPreference();
    setState(() {
      _p = p;
      _notifyOnUpdate = notifyPref;
      if (p != null) {
        _lastWait = p.estimatedWaitMinutes;
        _lastStatusText = p.statusMessage ?? p.status;
      }
    });
    if (p != null) {
      _refreshQueue();
    }
  }

  Future<void> _refreshQueue() async {
    final current = await StorageService.getAuthPatient();
    if (current == null) return;

    setState(() => _refreshing = true);
    try {
      final status = await TriageService().fetchQueueStatus(current.nationalId);
      if (status == null) return;

      Patient updated;
      if (status.found == false) {
        final isNew = current.status == 'TRIAGE_WAITING' || current.status == null;
        updated = current.copyWith(
          status: isNew ? 'TRIAGE_WAITING' : 'DONE',
          statusMessage: isNew 
            ? 'Kaydınız alındı, triyaj sırasına ekleniyor...' 
            : (status.message ?? 'Bugün için aktif randevunuz bulunmamaktadır.'),
          estimatedWaitMinutes: null,
          colorCode: null,
        );
      } else {
        final newWait = status.estimatedWaitMinutes ?? current.estimatedWaitMinutes;
        final newStatusText = status.message ?? status.status ?? current.status;
        final hasChange = (_lastWait != null && newWait != _lastWait) ||
            (_lastStatusText != null && newStatusText != _lastStatusText);

        updated = current.copyWith(
          queueNumber: status.queueNumber ?? current.queueNumber,
          estimatedWaitMinutes: newWait,
          status: status.status ?? current.status,
          statusMessage: status.message ?? current.statusMessage,
          colorCode: status.colorCode ?? current.colorCode,
        );

        if (_notifyOnUpdate && hasChange) {
          _playAlert();
        }
      }

      await StorageService.saveLastPatient(updated);
      await StorageService.saveAuthPatient(updated);
      setState(() {
        _p = updated;
        _lastWait = updated.estimatedWaitMinutes;
        _lastStatusText = updated.statusMessage ?? updated.status;
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Durum Takibi',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientCardPage()),
            ),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFF),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: p == null ? _buildNoRecordView() : _buildStateView(p),
      ),
    );
  }

  Widget _buildNoRecordView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
            ]),
            child: Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.noRecordYet, style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientCardPage()),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Geçmiş Muayenelerimi Gör'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateView(Patient p) {
    if (_isWaitingForTriage) return _buildWaitingForTriageState(p);
    if (_isCalled) return _buildCalledState(p);
    if (_isFinished) return _buildFinishedState(p);
    return _buildInQueueState(p);
  }

  Widget _buildWaitingForTriageState(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeroIcon(Icons.hourglass_empty_rounded, AppColors.primary),
          const SizedBox(height: 32),
          const Text('Kayıt Başarıyla Alındı', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Triyaj değerlendirmeniz henüz yapılmadı. Lütfen sıranızı bekleyin, uzman personelimiz sizi en kısa sürede değerlendirecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildPatientBriefCard(p),
          const SizedBox(height: 24),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCalledState(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.urgencyCritical.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.urgencyCritical.withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.notifications_active, size: 64, color: AppColors.urgencyCritical),
                const SizedBox(height: 16),
                const Text('MUAYENE SIRANIZ GELDİ!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.urgencyCritical)),
                const SizedBox(height: 8),
                const Text('Lütfen gecikmeden muayene odasına giriş yapınız.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.urgencyCritical, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPatientBriefCard(p),
          const SizedBox(height: 24),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildFinishedState(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeroIcon(Icons.check_circle_outline_rounded, Colors.green),
          const SizedBox(height: 32),
          const Text('Geçmiş Olsun', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text('Bugünkü tedavi süreciniz başarıyla tamamlanmıştır. Detayları aşağıdan kontrol edebilirsiniz.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          _buildPatientBriefCard(p),
          const SizedBox(height: 24),
          _buildActionLink('Hasta Kartını Görüntüle', Icons.contact_page_outlined),
        ],
      ),
    );
  }

  Widget _buildInQueueState(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (p.colorCode != null) _buildColorCodeBanner(p.colorCode!),
          _buildPatientBriefCard(p, showQueue: true),
          const SizedBox(height: 24),
          _buildRefreshButton(),
          const SizedBox(height: 16),
          _buildNotificationToggle(),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10),
      ]),
      child: Icon(icon, size: 72, color: color),
    );
  }

  Widget _buildPatientBriefCard(Patient p, {bool showQueue = false}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      color: Colors.white.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppColors.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(p.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                _buildStatusChip(p),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.badge_outlined, "${AppStrings.nationalId}: ${p.nationalId}"),
            if (p.createdAt != null) _buildInfoRow(Icons.event_note_outlined, "${AppStrings.createdAt}: ${_formatDateTime(p.createdAt!)}"),
            _buildSymptomsSection(p),
            if (showQueue) ...[
              const Divider(height: 32),
              _buildQueueSection(p),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection(Patient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(AppStrings.symptoms, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: p.symptoms.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildQueueSection(Patient p) {
    final waitTime = p.estimatedWaitMinutes ?? UrgencyHelper.getEstimatedWaitTime(p.queueNumber);
    return Column(
      children: [
        const Text('BEKLEME SIRASI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 3)),
          child: Center(child: Text('${p.queueNumber}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primaryDark))),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('~ $waitTime dk.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(Patient p) {
    final status = (p.status ?? '').toUpperCase();
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildColorCodeBanner(String colorCode) {
    final color = colorCode.toUpperCase() == 'KIRMIZI' ? Colors.red : (colorCode.toUpperCase() == 'SARI' ? Colors.amber : Colors.green);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text('$colorCode KOD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1))),
    );
  }

  Widget _buildActionLink(String label, IconData icon) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton(
      onPressed: _refreshing ? null : _refreshQueue,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: _refreshing
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh), SizedBox(width: 10), Text('Durumu Güncelle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.volume_up_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Değişikliklerde sesli uyarı', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Switch(
            value: _notifyOnUpdate,
            onChanged: (v) async {
              setState(() => _notifyOnUpdate = v);
              await StorageService.saveNotifyPreference(v);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _playAlert() => SystemSound.play(SystemSoundType.alert);

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CALLED': return Colors.redAccent;
      case 'IN_QUEUE': return Colors.blue;
      case 'TRIAGE_WAITING': return Colors.orange;
      case 'DONE': return Colors.green;
      default: return AppColors.primary;
    }
  }
}
