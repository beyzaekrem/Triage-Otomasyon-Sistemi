package com.acil.er_backend.service;

import com.acil.er_backend.dto.CreateTriageRequest;
import com.acil.er_backend.model.Appointment;
import com.acil.er_backend.model.TriageRecord;
import com.acil.er_backend.repository.AppointmentRepository;
import com.acil.er_backend.repository.TriageRecordRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TriageServiceImpl implements TriageService {

    private static final Logger logger = LoggerFactory.getLogger(TriageServiceImpl.class);

    private final AppointmentRepository appointmentRepository;
    private final TriageRecordRepository triageRecordRepository;
    private final MedicalInferenceService inferenceService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public TriageServiceImpl(AppointmentRepository appointmentRepository,
                             TriageRecordRepository triageRecordRepository,
                             MedicalInferenceService inferenceService) {
        this.appointmentRepository = appointmentRepository;
        this.triageRecordRepository = triageRecordRepository;
        this.inferenceService = inferenceService;
    }

    @Override
    @Transactional
    public TriageRecord create(CreateTriageRequest req) {
        logger.info("Triage kaydı oluşturuluyor - appointmentId: {}", req.appointmentId);
        Appointment ap = appointmentRepository.findById(req.appointmentId)
                .orElseThrow(() -> new RuntimeException("Randevu bulunamadı: " + req.appointmentId));

        TriageRecord tr = new TriageRecord();
        tr.setAppointment(ap);
        tr.setNurseSymptomsCsv(req.nurseSymptomsCsv);
        tr.setTemperature(req.temperature);
        tr.setPulse(req.pulse);
        tr.setBpHigh(req.bpHigh);
        tr.setBpLow(req.bpLow);
        tr.setPainLevel(req.painLevel);
        tr.setTriageLevel(req.triageLevel);
        tr.setNotes(req.notes);
        tr.setCreatedAt(LocalDateTime.now());

        // Öneriler: sadece {urgency_level, reasoning}
        List<String> nurseSymptoms = parseCsv(req.nurseSymptomsCsv);
        try {
            var minimalSuggestions = inferenceService.suggestTop5(nurseSymptoms);
            if (minimalSuggestions != null && !minimalSuggestions.isEmpty()) {
                tr.setSuggestionsJson(objectMapper.writeValueAsString(minimalSuggestions));
                logger.debug("Triage önerileri eklendi - {} öneri", minimalSuggestions.size());
            }
        } catch (Exception e) {
            logger.warn("Triage önerileri oluşturulamadı", e);
        }

        TriageRecord saved = triageRecordRepository.save(tr);
        logger.info("Triage kaydı oluşturuldu - triageId: {}, appointmentId: {}", saved.getId(), req.appointmentId);
        return saved;
    }

    @Override
    public List<TriageRecord> listByAppointment(Long appointmentId) {
        return triageRecordRepository.findByAppointment_IdOrderByCreatedAtDesc(appointmentId);
    }

    // ---- yardımcılar ----
    private static List<String> parseCsv(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .collect(Collectors.toList());
    }
}
