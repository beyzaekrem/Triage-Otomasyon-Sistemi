package com.acil.er_backend.controller;

import com.acil.er_backend.dto.ApiResponse;
import com.acil.er_backend.model.Patient;
import com.acil.er_backend.service.PatientService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;

    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    // 1) Yeni hasta (name, tc, basicSymptomsCsv opsiyonel)
    @PostMapping
    public ResponseEntity<ApiResponse<Patient>> createPatient(@RequestBody @Valid Patient patient) {
        if (patient.getTc() == null || patient.getTc().length() != 11) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("TC 11 haneli olmalı."));
        }
        if (patientService.existsByTc(patient.getTc())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Bu TC ile kayıtlı hasta zaten var."));
        }
        Patient savedPatient = patientService.savePatient(patient);
        return ResponseEntity.ok(ApiResponse.success("Hasta başarıyla oluşturuldu.", savedPatient));
    }

    // 2) Tüm hastalar
    @GetMapping
    public ResponseEntity<ApiResponse<List<Patient>>> getAllPatients() {
        return ResponseEntity.ok(ApiResponse.success(patientService.getAllPatients()));
    }

    // 3) ID ile hasta
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Patient>> getPatientById(@PathVariable Long id) {
        Patient patient = patientService.getPatientById(id);
        if (patient == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(ApiResponse.success(patient));
    }

    // 4) Hasta sil
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePatient(@PathVariable Long id) {
        patientService.deletePatient(id);
        return ResponseEntity.ok(ApiResponse.success("Hasta başarıyla silindi.", null));
    }

    // 5) PUT tam güncelleme (name, tc, basicSymptomsCsv)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Patient>> updatePatient(
            @PathVariable Long id, 
            @RequestBody @Valid Patient updatedPatient) {
        try {
            Patient updated = patientService.updatePatient(id, updatedPatient);
            return ResponseEntity.ok(ApiResponse.success("Hasta başarıyla güncellendi.", updated));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // 6) PATCH kısmi güncelleme
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<Patient>> partialUpdatePatient(
            @PathVariable Long id, 
            @RequestBody Patient partialPatient) {
        try {
            Patient updated = patientService.partialUpdatePatient(id, partialPatient);
            return ResponseEntity.ok(ApiResponse.success("Hasta başarıyla güncellendi.", updated));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
