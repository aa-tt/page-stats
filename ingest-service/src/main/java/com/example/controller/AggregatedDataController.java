package com.example.controller;
import com.example.model.PageViewStats;
import com.example.repository.PageViewStatsRowMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@RestController
@RequestMapping("/aggregated-data")
public class AggregatedDataController {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/region-weekly")
    public List<PageViewStats> getRegionWeeklyData(
            @RequestParam String region,
            @RequestParam String startTime,
            @RequestParam String endTime) {
                String sql = "SELECT pageName, SUM(visits) as visits FROM region_weekly WHERE region = ? AND timestamp BETWEEN CAST(? AS TIMESTAMP) AND CAST(? AS TIMESTAMP) GROUP BY pageName";
        return jdbcTemplate.query(sql, new Object[]{region, startTime, endTime}, new PageViewStatsRowMapper());
    }

    // Similarly, implement endpoints for region-monthly, region-hourly, region-daily
}