import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final List<dynamic> triageRecords;
  final List<dynamic> doctorNotes;

  const HistoryDetailPage({
    super.key,
    required this.appointment,
    required this.triageRecords,
    required this.doctorNotes,
  });

  @override
  Widget build(BuildContext context) {
    // Bu randevuya ait kayıtları filtrele
    final myTriage = triageRecords.where((t) => t['appointment']?['id'] == appointment['id']).toList();
    final myNotes = doctorNotes.where((n) => n['appointment']?['id'] == appointment['id']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Muayene Detayı', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickSummary(),
            const SizedBox(height: 24),
            if (myTriage.isNotEmpty) ...[
              _buildSectionTitle('TRİYAJ VE VİTAL BULGULAR'),
              ...myTriage.map((t) => _buildTriageCard(t)).toList(),
              const SizedBox(height: 24),
            ],
            if (myNotes.isNotEmpty) ...[
              _buildSectionTitle('DOKTOR NOTLARI VE TANI'),
              ...myNotes.map((n) => _buildDoctorNoteCard(n)).toList(),
            ] else if (appointment['status'] == 'DONE')
              _buildNoDataCard('Bu muayene için henüz doktor notu girilmemiş.'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummary() {
    final date = appointment['createdAt']?.toString().split('T').first ?? '';
    final color = (appointment['currentTriageColor'] ?? 'GRAY').toString().toUpperCase();
    
    Color statusColor = AppColors.textTertiary;
    if (color == 'KIRMIZI') statusColor = Colors.red;
    else if (color == 'SARI') statusColor = Colors.orange;
    else if (color == 'YESIL') statusColor = Colors.green;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.event_available, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Sıra No: ${appointment['queueNumber'] ?? '-'} • Durum: ${_getStatusLabel(appointment['status'])}',
                    style: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.5)),
    );
  }

  Widget _buildTriageCard(dynamic t) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildVitalRow('Vücut Isısı', '${t['temperature'] ?? '-'} °C', Icons.thermostat),
            _buildVitalRow('Nabız', '${t['pulse'] ?? '-'} bpm', Icons.favorite),
            _buildVitalRow('Tansiyon', '${t['bpHigh'] ?? '-'}/${t['bpLow'] ?? '-'} mmHg', Icons.speed),
            _buildVitalRow('Oksijen', '%${t['oxygenSaturation'] ?? '-'}', Icons.air),
            if (t['notes'] != null) ...[
              const Divider(height: 24),
              Text(t['notes'], style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDoctorNoteCard(dynamic n) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.primary, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Tanı ve Teşhis', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(n['diagnosis'] ?? 'Tanı belirtilmemiş', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
            if (n['plan'] != null) ...[
              const Divider(height: 32),
              const Text('Tedavi Planı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Text(n['plan'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ],
            if (n['prescription'] != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REÇETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text(n['prescription'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
    );
  }

  String _getStatusLabel(String? status) {
    if (status == null) return '-';
    switch (status.toUpperCase()) {
      case 'WAITING': return 'Bekliyor';
      case 'CALLED': return 'Çağrıldı';
      case 'IN_PROGRESS': return 'Muayenede';
      case 'DONE': return 'Tamamlandı';
      default: return status;
    }
  }
}
