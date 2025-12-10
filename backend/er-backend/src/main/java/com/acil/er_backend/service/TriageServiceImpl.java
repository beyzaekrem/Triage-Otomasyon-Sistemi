package com.acil.er_backend.service;

import com.acil.er_backend.dto.CreateTriageRequest;
import com.acil.er_backend.model.Appointment;
import com.acil.er_backend.model.TriageRecord;
import com.acil.er_backend.repository.AppointmentRepository;
import com.acil.er_backend.repository.TriageRecordRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class TriageServiceImpl implements TriageService {

    private final AppointmentRepository appointmentRepository;
    private final TriageRecordRepository triageRecordRepository;
    private final MedicalDataService medicalDataService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public TriageServiceImpl(AppointmentRepository appointmentRepository,
            TriageRecordRepository triageRecordRepository,
            MedicalDataService medicalDataService) {
        this.appointmentRepository = appointmentRepository;
        this.triageRecordRepository = triageRecordRepository;
        this.medicalDataService = medicalDataService;
    }

    @Override
    @Transactional
    public TriageRecord create(CreateTriageRequest req) {
        Appointment ap = appointmentRepository.findById(req.getAppointmentId())
                .orElseThrow(() -> new RuntimeException("Randevu bulunamadı: " + req.getAppointmentId()));

        TriageRecord tr = new TriageRecord();
        tr.setAppointment(ap);
        tr.setNurseSymptomsCsv(req.getNurseSymptomsCsv());
        tr.setTemperature(req.getTemperature());
        tr.setPulse(req.getPulse());
        tr.setBpHigh(req.getBpHigh());
        tr.setBpLow(req.getBpLow());
        tr.setOxygenSaturation(req.getOxygenSaturation());
        tr.setRespiratoryRate(req.getRespiratoryRate());
        tr.setPainLevel(req.getPainLevel());
        tr.setBloodGlucose(req.getBloodGlucose());
        tr.setTriageLevel(req.getTriageLevel());
        tr.setNotes(req.getNotes());
        tr.setCreatedAt(LocalDateTime.now());

        try {
            tr.setCreatedBy(SecurityContextHolder.getContext().getAuthentication().getName());
        } catch (Exception e) {
            tr.setCreatedBy("system");
        }

        List<String> symptoms = parseCsv(req.getNurseSymptomsCsv());
        try {
            // Veri setinden eşleşen kayıtları getir (AI inference yok, sadece veri seti)
            List<Map<String, Object>> matches = medicalDataService.searchBySymptoms(symptoms);
            if (matches != null && !matches.isEmpty()) {
                // Eşleşme skoruna göre sırala ve ilk 5'i al
                List<Map<String, Object>> scored = new ArrayList<>();
                for (Map<String, Object> rec : matches) {
                    Object symptomsObj = rec.get("symptoms");
                    int matchCount = 0;
                    if (symptomsObj instanceof List<?> list) {
                        for (Object s : list) {
                            if (s != null) {
                                String lower = s.toString().toLowerCase().trim();
                                for (String input : symptoms) {
                                    if (lower.equals(input.toLowerCase().trim())) {
                                        matchCount++;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    Map<String, Object> copy = new HashMap<>(rec);
                    copy.put("match_score", matchCount);
                    scored.add(copy);
                }

                List<Map<String, Object>> top5 = scored.stream()
                        .sorted((a, b) -> {
                            int scoreA = (int) a.getOrDefault("match_score", 0);
                            int scoreB = (int) b.getOrDefault("match_score", 0);
                            if (scoreB != scoreA) return scoreB - scoreA;
                            Object uA = a.get("urgency_level");
                            Object uB = b.get("urgency_level");
                            int urgA = uA != null ? Integer.parseInt(uA.toString()) : 0;
                            int urgB = uB != null ? Integer.parseInt(uB.toString()) : 0;
                            return urgB - urgA;
                        })
                        .limit(5)
                        .collect(Collectors.toList());

                if (!top5.isEmpty()) {
                    tr.setSuggestionsJson(objectMapper.writeValueAsString(top5));
                    int maxUrgency = top5.stream()
                            .mapToInt(s -> {
                                Object level = s.get("urgency_level");
                                return level != null ? Integer.parseInt(level.toString()) : 0;
                            })
                            .max().orElse(0);
                    tr.setAiSuggestedLevel(maxUrgency >= 4 ? "KIRMIZI" : maxUrgency >= 3 ? "SARI" : "YESIL");
                    tr.setAiConfidence((int) Math.min(100, 50 + top5.size() * 10));
                }
            }
        } catch (Exception ignored) {}

        return triageRecordRepository.save(tr);
    }

    @Override
    public List<TriageRecord> listByAppointment(Long appointmentId) {
        return triageRecordRepository.findByAppointment_IdOrderByCreatedAtDesc(appointmentId);
    }

    private List<String> parseCsv(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(",")).map(String::trim).filter(s -> !s.isBlank()).collect(Collectors.toList());
    }
}
