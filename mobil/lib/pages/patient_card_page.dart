import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/storage_service.dart';
import '../models/patient.dart';
import '../utils/urgency_helper.dart';

class PatientCardPage extends StatefulWidget {
  const PatientCardPage({super.key});

  @override
  State<PatientCardPage> createState() => _PatientCardPageState();
}

class _PatientCardPageState extends State<PatientCardPage> {
  Patient? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await StorageService.getLastPatient();
    setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.patientCardTitle)),
      body: p == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.recordNotFound,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(p),
                      const Divider(height: 32),
                      _buildPatientInfo(p),
                      const SizedBox(height: 24),
                      _buildUrgencyInfo(p),
                      const SizedBox(height: 24),
                      _buildSymptomsInfo(p),
                      if (p.createdAt != null) ...[
                        const SizedBox(height: 24),
                        _buildTimestampInfo(p),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(Patient p) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${AppStrings.nationalId}: ${p.nationalId}",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(Patient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.confirmation_number,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "${AppStrings.queueNumber}:",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              "${p.queueNumber}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencyInfo(Patient p) {
    final urgencyColor = UrgencyHelper.getUrgencyColor(p.urgencyLabel);
    final urgencyIcon = UrgencyHelper.getUrgencyIcon(p.urgencyLabel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(urgencyIcon, color: urgencyColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.urgency,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  p.urgencyLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: urgencyColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsInfo(Patient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.symptoms,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.symptoms.map((symptom) {
            return Chip(
              label: Text(symptom),
              backgroundColor: AppColors.surfaceVariant,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimestampInfo(Patient p) {
    final dateTime = p.createdAt!;
    final formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    final formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          "Kayıt Tarihi: $formattedDate $formattedTime",
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
