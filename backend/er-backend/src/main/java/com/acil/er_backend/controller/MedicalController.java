package com.acil.er_backend.controller;

import com.acil.er_backend.dto.ApiResponse;
import com.acil.er_backend.service.MedicalDataService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/medical")
public class MedicalController {

    private final MedicalDataService medicalDataService;

    public MedicalController(MedicalDataService medicalDataService) {
        this.medicalDataService = medicalDataService;
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> searchBySymptoms(
            @RequestParam(required = false) List<String> symptoms) {
        if (symptoms == null || symptoms.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Lütfen en az bir semptom girin."));
        }

        List<Map<String, Object>> medicalData = medicalDataService.getAllMedicalData();
        List<Map<String, Object>> matched = new ArrayList<>();

        for (Map<String, Object> item : medicalData) {
            @SuppressWarnings("unchecked")
            List<String> itemSymptoms = (List<String>) item.get("symptoms");
            if (itemSymptoms == null) continue;

            long matchCount = symptoms.stream()
                    .filter(symptom -> itemSymptoms.stream()
                            .anyMatch(s -> s.toLowerCase().contains(symptom.toLowerCase())))
                    .count();

            if (matchCount > 0) {
                Map<String, Object> copy = new HashMap<>(item);
                copy.put("matchScore", matchCount);
                matched.add(copy);
            }
        }

        List<Map<String, Object>> result = matched.stream()
                .sorted((a, b) -> Long.compare((Long) b.get("matchScore"), (Long) a.get("matchScore")))
                .limit(5)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/symptoms")
    public ResponseEntity<ApiResponse<List<String>>> allSymptoms() {
        List<Map<String, Object>> medicalData = medicalDataService.getAllMedicalData();
        List<String> symptoms = medicalData.stream()
                .flatMap(m -> {
                    @SuppressWarnings("unchecked")
                    List<String> syms = (List<String>) m.getOrDefault("symptoms", List.of());
                    return syms.stream();
                })
                .map(String::toLowerCase)
                .distinct()
                .sorted()
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(symptoms));
    }
}
