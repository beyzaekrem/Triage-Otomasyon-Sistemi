package com.acil.er_backend.config;

import com.acil.er_backend.dto.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Uygulama genelinde hata yakalayıcı.
 * - Validasyon hatalarını JSON olarak döner.
 * - NotFound ve Runtime hatalarını tek formatta gösterir.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // 🔹 @Valid hataları (RequestBody, PathVariable vs.)
    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleValidation(Exception ex) {
        Map<String, String> errors = new HashMap<>();
        var binding = ex instanceof MethodArgumentNotValidException manv
                ? manv.getBindingResult()
                : ((BindException) ex).getBindingResult();

        binding.getFieldErrors().forEach(fe -> 
            errors.put(fe.getField(), fe.getDefaultMessage())
        );

        logger.warn("Validation hatası: {}", errors);
        return ResponseEntity.badRequest().body(
            ApiResponse.error("Validasyon hatası", Map.of("errors", errors))
        );
    }

    // 🔹 NotFound (örnek: hasta/randevu bulunamadı)
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ApiResponse<Void>> notFound(NoSuchElementException ex) {
        logger.warn("Kayıt bulunamadı: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    // 🔹 IllegalArgumentException
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> illegalArgument(IllegalArgumentException ex) {
        logger.warn("Geçersiz argüman: {}", ex.getMessage());
        return ResponseEntity.badRequest()
                .body(ApiResponse.error(ex.getMessage()));
    }

    // 🔹 Diğer hatalar (iş mantığı, parse vs.)
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Void>> runtime(RuntimeException ex) {
        logger.error("Runtime hatası: ", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Bir hata oluştu: " + ex.getMessage()));
    }

    // 🔹 Genel exception handler
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception ex) {
        logger.error("Beklenmeyen hata: ", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Beklenmeyen bir hata oluştu."));
    }
}
