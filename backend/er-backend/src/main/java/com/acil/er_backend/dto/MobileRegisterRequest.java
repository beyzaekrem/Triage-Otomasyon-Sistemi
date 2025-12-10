package com.acil.er_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * Hasta mobil kayıt isteği (semptom zorunlu değil).
 */
public class MobileRegisterRequest {

    @NotBlank(message = "Ad soyad zorunludur.")
    private String fullName;

    @NotBlank(message = "TC zorunludur.")
    @Pattern(regexp = "^[0-9]{11}$", message = "TC 11 haneli olmalıdır.")
    private String tc;

    // Opsiyonel
    private Integer birthYear;
    private String gender; // E / K

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getTc() { return tc; }
    public void setTc(String tc) { this.tc = tc; }

    public Integer getBirthYear() { return birthYear; }
    public void setBirthYear(Integer birthYear) { this.birthYear = birthYear; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
}

