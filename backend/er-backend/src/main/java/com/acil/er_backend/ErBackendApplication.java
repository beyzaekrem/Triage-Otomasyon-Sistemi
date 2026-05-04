package com.acil.er_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.context.annotation.Bean;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
public class ErBackendApplication {
    public static void main(String[] args) {
        SpringApplication.run(ErBackendApplication.class, args);
    }

    @Bean
    CommandLineRunner fixDatabaseConstraints(JdbcTemplate jdbcTemplate) {
        return args -> {
            try {
                // 'NO_SHOW' statüsü sonradan eklendiği için eski kuralı siliyoruz
                jdbcTemplate.execute("ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_status_check;");
                System.out.println("✅ Database constraint 'appointments_status_check' dropped successfully (if it existed).");
            } catch (Exception e) {
                System.out.println("⚠️ Could not drop constraint (maybe not PostgreSQL or doesn't exist): " + e.getMessage());
            }
        };
    }
}
