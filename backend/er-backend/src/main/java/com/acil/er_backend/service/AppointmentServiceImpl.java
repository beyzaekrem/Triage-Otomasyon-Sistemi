package com.acil.er_backend.service;

import com.acil.er_backend.dto.AppointmentDetailResponse;
import com.acil.er_backend.model.Appointment;
import com.acil.er_backend.model.AppointmentStatus;
import com.acil.er_backend.model.Patient;
import com.acil.er_backend.repository.AppointmentRepository;
import com.acil.er_backend.repository.DoctorNoteRepository;
import com.acil.er_backend.repository.PatientRepository;
import com.acil.er_backend.repository.TriageRecordRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
public class AppointmentServiceImpl implements AppointmentService {

    private static final Logger logger = LoggerFactory.getLogger(AppointmentServiceImpl.class);

    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final TriageRecordRepository triageRecordRepository;
    private final DoctorNoteRepository doctorNoteRepository;

    public AppointmentServiceImpl(AppointmentRepository appointmentRepository,
                                  PatientRepository patientRepository,
                                  TriageRecordRepository triageRecordRepository,
                                  DoctorNoteRepository doctorNoteRepository) {
        this.appointmentRepository = appointmentRepository;
        this.patientRepository = patientRepository;
        this.triageRecordRepository = triageRecordRepository;
        this.doctorNoteRepository = doctorNoteRepository;
    }

    @Override
    @Transactional
    public Appointment createAppointment(Long patientId) {
        logger.info("Randevu oluşturuluyor - patientId: {}", patientId);
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new NoSuchElementException("Hasta bulunamadı: id=" + patientId));

        LocalDate today = LocalDate.now();
        int maxQueue = appointmentRepository.findTodayMaxQueueNumber(today);
        int nextQueue = maxQueue + 1;

        Appointment ap = new Appointment();
        ap.setPatient(patient);
        ap.setQueueNumber(nextQueue);
        ap.setAppointmentDate(today);
        ap.setStatus(AppointmentStatus.WAITING);

        Appointment saved = appointmentRepository.save(ap);
        logger.info("Randevu oluşturuldu - appointmentId: {}, queueNumber: {}", saved.getId(), nextQueue);
        return saved;
    }

    @Override
    public Optional<Appointment> findTodayActiveByTc(String tc) {
        return appointmentRepository.findTodayActiveByTc(tc, LocalDate.now());
    }

    @Override
    public long countWaitingAheadFor(Appointment appointment) {
        return appointmentRepository.countWaitingAhead(
                appointment.getAppointmentDate(),
                AppointmentStatus.WAITING,
                appointment.getQueueNumber()
        );
    }

    @Override
    public List<Appointment> listToday() {
        return appointmentRepository.findByAppointmentDateOrderByQueueNumberAsc(LocalDate.now());
    }

    @Override
    public List<Appointment> listTodayByStatus(AppointmentStatus status) {
        return appointmentRepository.findByAppointmentDateAndStatusOrderByQueueNumberAsc(LocalDate.now(), status);
    }

    @Override
    @Transactional
    public Appointment updateStatus(Long appointmentId, AppointmentStatus newStatus) {
        logger.info("Randevu durumu güncelleniyor - appointmentId: {}, yeni durum: {}", appointmentId, newStatus);
        Appointment ap = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new NoSuchElementException("Randevu bulunamadı: id=" + appointmentId));
        ap.setStatus(newStatus);
        Appointment saved = appointmentRepository.save(ap);
        logger.info("Randevu durumu güncellendi - appointmentId: {}, durum: {}", saved.getId(), newStatus);
        return saved;
    }

    @Override
    @Transactional
    public void deleteAppointment(Long id) {
        if (!appointmentRepository.existsById(id)) {
            throw new NoSuchElementException("Randevu bulunamadı: id=" + id);
        }
        appointmentRepository.deleteById(id);
    }

    @Override
    public AppointmentDetailResponse getAppointmentDetail(Long appointmentId) {
        Appointment ap = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new NoSuchElementException("Randevu bulunamadı: id=" + appointmentId));
        
        AppointmentDetailResponse dto = new AppointmentDetailResponse();
        dto.appointment = ap;
        dto.patient = ap.getPatient();
        dto.triageRecords = triageRecordRepository.findByAppointment_IdOrderByCreatedAtDesc(appointmentId);
        dto.doctorNotes = doctorNoteRepository.findByAppointment_IdOrderByCreatedAtDesc(appointmentId);
        
        return dto;
    }
}
