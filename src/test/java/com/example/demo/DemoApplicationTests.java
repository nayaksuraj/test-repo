package com.example.demo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class DemoApplicationTests {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void contextLoads() {
        // Verifies that the application context loads successfully
    }

    @Test
    void testHelloEndpoint() {
        String response = restTemplate.getForObject("/", String.class);
        assertThat(response).isEqualTo("Hello, Spring Boot!");
    }

    @Test
    void testHealthEndpoint() {
        String response = restTemplate.getForObject("/health", String.class);
        assertThat(response).isEqualTo("OK");
    }
}
