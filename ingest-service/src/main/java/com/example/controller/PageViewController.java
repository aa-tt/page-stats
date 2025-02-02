package com.example.controller;

import com.example.model.PageViewEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/page-view")
public class PageViewController {
    @Autowired
    private KafkaTemplate<String, PageViewEvent> kafkaTemplate;

    private static final String TOPIC = "page_view_events";

    @PostMapping
    public ResponseEntity<Void> trackPageView(@RequestBody PageViewEvent event) {
        kafkaTemplate.send(TOPIC, event.getRegion(), event);
        return ResponseEntity.ok().build();
    }
}