package com.acil.er_backend.controller;

import com.acil.er_backend.dto.ApiResponse;
import com.acil.er_backend.service.MedicalDataService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/medical")
public class MedicalDataController {

    private final MedicalDataService medicalDataService;

    public MedicalDataController(MedicalDataService medicalDataService) {
        this.medicalDataService = medicalDataService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllData() {
        return ResponseEntity.ok(ApiResponse.success(medicalDataService.getAllMedicalData()));
    }
}
