package com.acil.er_backend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

@Entity
@Table(name = "patients", uniqueConstraints = {
        @UniqueConstraint(name = "uk_patients_tc", columnNames = {"tc"})
})
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Tam isim
    @NotBlank(message = "İsim boş olamaz")
    @Size(min = 2, max = 100, message = "İsim 2-100 karakter arasında olmalıdır")
    @Column(nullable = false)
    private String name;

    // 11 haneli TC (benzersiz)
    @NotBlank(message = "TC kimlik numarası boş olamaz")
    @Pattern(regexp = "\\d{11}", message = "TC kimlik numarası 11 haneli olmalıdır")
    @Column(nullable = false, length = 11, unique = true)
    private String tc;

    // Mobilin seçeceği basic düzey semptomlar (virgül ile ayrılmış liste)
    @Column(columnDefinition = "TEXT")
    private String basicSymptomsCsv;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    // --- GETTER / SETTER ---
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getTc() { return tc; }
    public void setTc(String tc) { this.tc = tc; }

    public String getBasicSymptomsCsv() { return basicSymptomsCsv; }
    public void setBasicSymptomsCsv(String basicSymptomsCsv) { this.basicSymptomsCsv = basicSymptomsCsv; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
