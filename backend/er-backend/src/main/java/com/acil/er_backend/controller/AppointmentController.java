package com.acil.er_backend.controller;

import com.acil.er_backend.dto.ApiResponse;
import com.acil.er_backend.dto.AppointmentDetailResponse;
import com.acil.er_backend.model.Appointment;
import com.acil.er_backend.model.AppointmentStatus;
import com.acil.er_backend.service.AppointmentService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;

    public AppointmentController(AppointmentService appointmentService) {
        this.appointmentService = appointmentService;
    }

    // 1) Randevu oluştur
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(
            @RequestBody @Valid CreateAppointmentRequest req) {
        Appointment ap = appointmentService.createAppointment(req.patientId);
        long ahead = appointmentService.countWaitingAheadFor(ap);

        Map<String, Object> resp = new HashMap<>();
        resp.put("appointmentId", ap.getId());
        resp.put("queueNumber", ap.getQueueNumber());
        resp.put("status", ap.getStatus().name());
        resp.put("aheadCount", ahead);
        resp.put("appointmentDate", ap.getAppointmentDate().toString());
        
        return ResponseEntity.ok(ApiResponse.success("Randevu başarıyla oluşturuldu.", resp));
    }

    // 2) TC ile durum
    @GetMapping("/status/{tc}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> status(@PathVariable String tc) {
        return appointmentService.findTodayActiveByTc(tc)
                .<ResponseEntity<ApiResponse<Map<String, Object>>>>map(ap -> {
                    long ahead = appointmentService.countWaitingAheadFor(ap);
                    Map<String, Object> data = Map.of(
                            "appointmentId", ap.getId(),
                            "appointmentDate", ap.getAppointmentDate().toString(),
                            "status", ap.getStatus().name(),
                            "aheadCount", ahead,
                            "queueNumber", ap.getQueueNumber());
                    return ResponseEntity.ok(ApiResponse.success(data));
                })
                .orElseGet(() -> ResponseEntity.ok(ApiResponse.success(
                        Map.of("hasActive", false, "message", "Bugün için aktif randevu bulunamadı."))));
    }

    // 3) Bugünkü randevular
    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<Appointment>>> today(
            @RequestParam(required = false) AppointmentStatus status) {
        List<Appointment> appointments = status != null 
                ? appointmentService.listTodayByStatus(status)
                : appointmentService.listToday();
        return ResponseEntity.ok(ApiResponse.success(appointments));
    }

    // 3.a) Bugün - sıradaki bekleyen (en küçük sıra numarası)
    @GetMapping("/today/next")
    public ResponseEntity<ApiResponse<Map<String, Object>>> nextWaiting() {
        List<Appointment> waiting = appointmentService.listTodayByStatus(AppointmentStatus.WAITING);
        if (waiting.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success(Map.of("hasNext", false)));
        }
        Appointment next = waiting.get(0);
        Map<String, Object> data = Map.of(
                "hasNext", true,
                "appointmentId", next.getId(),
                "queueNumber", next.getQueueNumber(),
                "patient", next.getPatient());
        return ResponseEntity.ok(ApiResponse.success(data));
    }

    // 4) Durum güncelle
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateStatus(
            @PathVariable Long id, 
            @RequestParam @NotNull AppointmentStatus status) {
        Appointment ap = appointmentService.updateStatus(id, status);
        Map<String, Object> data = Map.of(
                "appointmentId", ap.getId(),
                "status", ap.getStatus().name());
        return ResponseEntity.ok(ApiResponse.success("Durum güncellendi.", data));
    }

    // 5) Sil
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deleteAppointment(@PathVariable Long id) {
        appointmentService.deleteAppointment(id);
        return ResponseEntity.ok(ApiResponse.success(
                "Randevu başarıyla silindi.", Map.of("appointmentId", id)));
    }

    // 6) Doktor ekranı: detay (DTO ile)
    @GetMapping("/{id}/detail")
    public ResponseEntity<ApiResponse<AppointmentDetailResponse>> detail(@PathVariable Long id) {
        AppointmentDetailResponse dto = appointmentService.getAppointmentDetail(id);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    // --- DTO ---
    public static class CreateAppointmentRequest {
        @NotNull(message = "patientId gerekli")
        public Long patientId;
    }

}
