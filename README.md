# Page Stats Dashboard

This README provides an overview of the Page Stats Dashboard, which is designed to create a dashboard for page visit statistics for an admin.

## Flow Overview

### UI Step [ui](ui)
- **Tracker.js** script on the webpage sends events when a page is visited.
- Event format: `(timestamp, region, pageName)`.
- **Dashboard.js** in the UI fetches and displays page stats.
- Fetches data from `/aggregated-data/region-weekly?region=&startTime=&endTime=` in the ingest-service API.


### API Step [ingest-service](ingest-service)
- Events are handled by **ingest-service** via the `/page-view` API.
- Events are published to Kafka topics `page_view_events`.

### InfluxDB Step [processing-service](processing-service)
- **processing-service** continuously consumes Kafka topics.
- Data is stored in a time-series database, InfluxDB, in the `page_view_bucket`.

### Spark Jobs Step [consolidator-service](consolidator-service)
- **consolidator-service** runs as a cron job (daily, monthly, weekly, etc.).
- Processes time-series data and runs aggregation on data from InfluxDB.
- Aggregated data is stored in various Postgres database tables: `region_daily`, `region_weekly`, `region_monthly`.

### Nginx Step [nginx.conf](ui/nginx.conf)
- **nginx** is used for proxy and routing requests to the API.

## Kubernetes Deployment [kind-zenoptics-app.yaml](kind-zenoptics-app.yaml)
- **Deployment Apps**: InfluxDB, Postgres, ingest-service, processing-service.
- **StatefulSet Apps**: Kafka, Zookeeper.
- **CronJob Batch**: consolidator-service.
- **Service LoadBalancer**: nginx.

## System Design
+-------------------+       +-------------------+       +-------------------+       +--------------------+
|                   |       |                   |       |                   |       |                    |
|   Webpage (UI)    |  POST |   Ingest-Service  |       |   Kafka Topic     |       |  Processing-Service|
|   (Tracker.js)    +------->   (/page-view)    +------->   (page_views)    +------->   (Consumes Kafka) |
|   (Dashboard.js)  |       |                   |       |                   |       |                    |
+--------+----------+       +-------------------+       +-------------------+       +---------+----------+
         |                                                                                    |
    GET  |                                                                                    |
         |                                                                                    |
         |                                                                                    |
+--------v----------+       +-------------------+       +---------------------+       +---------v-----------+
|                   |       |                   |       |                     |       |                     |
|   Ingest-Service  |       |   PostgreSQL      |       |   Consolidator      |       |       InfluxDB      |
| (/aggregated-data)+------>+   (region_daily,  +------->      Service        +<------+   (page_view_bucket)|
|                   |       |   region_weekly,  |       |  (Spark cron job)   |       |                     |
+-------------------+       |   region_monthly) |       +---------------------+       +---------------------+
                            +-------------------+                            
                                                        
