package com.acil.er_backend.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

@Service
@Slf4j
public class MedicalInferenceService {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public Map<String, Object> inferTriage(List<String> symptoms) {
        if (symptoms == null || symptoms.isEmpty()) {
            return fallback("YESIL", 100, "Hiçbir semptom belirtilmediği için YESIL olarak atandı.");
        }

        try {
            String symptomsCsv = String.join(", ", symptoms);

            // Robustly find the python script
            Path pythonScriptPath = null;
            Path current = Paths.get(System.getProperty("user.dir")).toAbsolutePath();
            while (current != null) {
                Path candidate = current.resolve("ml_triage").resolve("triage_inference.py");
                if (java.nio.file.Files.exists(candidate)) {
                    pythonScriptPath = candidate;
                    break;
                }
                current = current.getParent();
            }

            if (pythonScriptPath == null) {
                log.error("Could not find triage_inference.py in any parent directory.");
                return fallback("SARI", 50, "Python yapay zeka betiği bulunamadı.");
            }

            ProcessBuilder pb = new ProcessBuilder(
                    "python",
                    pythonScriptPath.toAbsolutePath().toString(),
                    symptomsCsv
            );
            
            pb.redirectErrorStream(true);
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                log.error("AI Inference failed with exit code: " + exitCode + ". Output: " + output);
                return fallback("SARI", 50, "Yapay zeka analiz servisine ulaşılamadı. Varsayılan olarak SARI atandı.");
            }

            // Parse output JSON
            String jsonOutput = output.toString().trim();
            Map<String, Object> result = objectMapper.readValue(jsonOutput, new TypeReference<Map<String, Object>>() {});
            
            if (result.containsKey("error")) {
                log.error("AI Inference returned error: " + result.get("error"));
                return fallback("SARI", 50, "Makine öğrenmesi modeli bir hata döndürdü: " + result.get("error"));
            }

            return result;

        } catch (Exception e) {
            log.error("Exception during AI Inference", e);
            return fallback("SARI", 50, "Sistem hatası nedeniyle analiz yapılamadı. Güvenlik amaçlı SARI atandı.");
        }
    }

    private Map<String, Object> fallback(String color, int confidence, String explanation) {
        Map<String, Object> res = new HashMap<>();
        res.put("color", color);
        res.put("confidence", confidence);
        res.put("explanation", explanation);
        return res;
    }
}
