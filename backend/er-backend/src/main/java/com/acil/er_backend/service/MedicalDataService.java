package com.acil.er_backend.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
public class MedicalDataService {

    private static final Logger logger = LoggerFactory.getLogger(MedicalDataService.class);
    private List<Map<String, Object>> medicalDataList = Collections.emptyList();

    @PostConstruct
    public void init() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            InputStream is = getClass().getClassLoader().getResourceAsStream("medical_data.json");
            if (is == null) {
                logger.error("medical_data.json dosyası bulunamadı!");
                return;
            }
            medicalDataList = mapper.readValue(is, new TypeReference<List<Map<String, Object>>>() {});
            logger.info("Medical data yüklendi: {} kayıt", medicalDataList.size());
        } catch (Exception e) {
            logger.error("Medical data yüklenirken hata oluştu", e);
        }
    }

    public List<Map<String, Object>> getAllMedicalData() {
        return medicalDataList;
    }
}
