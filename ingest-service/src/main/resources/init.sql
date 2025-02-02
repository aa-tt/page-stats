CREATE TABLE IF NOT EXISTS region_weekly (
    pageName VARCHAR(255),
    region VARCHAR(255),
    timestamp TIMESTAMP,
    visits INT
);

INSERT INTO region_weekly (pageName, region, timestamp, visits) VALUES
('HomePage', 'us-west', '2023-01-01 00:00:00', 100),
('HomePage', 'us-west', '2023-01-02 00:00:00', 150),
('ContactPage', 'us-west', '2023-01-01 00:00:00', 50),
('ContactPage', 'us-west', '2023-01-02 00:00:00', 75);