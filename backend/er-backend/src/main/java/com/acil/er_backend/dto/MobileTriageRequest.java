package com.acil.er_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import java.util.List;

/**
 * Minimal triage request that the mobile app sends before registration at the desk.
 * Only collects name/TC and selected symptoms.
 */
public class MobileTriageRequest {

    @NotBlank(message = "Ad soyad zorunludur.")
    private String fullName;

    @NotBlank(message = "TC zorunludur.")
    @Pattern(regexp = "^[0-9]{11}$", message = "TC 11 haneli olmalıdır.")
    private String tc;

    @NotEmpty(message = "Semptom listesi boş olamaz.")
    private List<String> symptoms;

    // Opsiyonel alanlar: Web/POSTMAN body'leriyle hizalama
    private Integer birthYear;
    /**
     * E / K opsiyonel; verilirse patient kaydına yazılır.
     */
    private String gender;
    /**
     * Opsiyonel chief complaint; verilmezse semptomlardan üretilir.
     */
    private String chiefComplaint;

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getTc() { return tc; }
    public void setTc(String tc) { this.tc = tc; }

    public List<String> getSymptoms() { return symptoms; }
    public void setSymptoms(List<String> symptoms) { this.symptoms = symptoms; }

    public Integer getBirthYear() { return birthYear; }
    public void setBirthYear(Integer birthYear) { this.birthYear = birthYear; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public String getChiefComplaint() { return chiefComplaint; }
    public void setChiefComplaint(String chiefComplaint) { this.chiefComplaint = chiefComplaint; }
}

