package com.example.repository;

import com.example.model.PageViewStats;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;

public class PageViewStatsRowMapper implements RowMapper<PageViewStats> {
    @Override
    public PageViewStats mapRow(ResultSet rs, int rowNum) throws SQLException {
        PageViewStats stats = new PageViewStats();
        stats.setPageName(rs.getString("pageName"));
        stats.setVisits(rs.getInt("visits"));
        return stats;
    }
}