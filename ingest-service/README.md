# Ingest Service

This project is a Spring Boot application designed to ingest and process page view statistics based on region and time parameters.

## Project Structure

```
ingest-service
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       └── example
│   │   │           ├── IngestServiceApplication.java
│   │   │           ├── controller
│   │   │           │   └── PageViewController.java
│   │   │           ├── model
│   │   │           │   └── PageViewStats.java
│   │   │           └── repository
│   │   │               └── PageViewStatsRowMapper.java
│   │   └── resources
│   │       └── application.properties
│   └── test
│       └── java
│           └── com
│               └── example
│                   └── IngestServiceApplicationTests.java
├── pom.xml
└── README.md
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd ingest-service
   ```

2. **Build the project:**
   ```
   mvn clean install
   ```

3. **Run the application:**
   ```
   mvn spring-boot:run
   ```

## Usage

The application exposes a REST API endpoint to retrieve page view statistics. 

### Endpoint

- `GET /region-weekly?region={region}&startTime={startTime}&endTime={endTime}`

This endpoint returns the page view statistics for a specified region and time range.

## Dependencies

This project uses Maven for dependency management. The required dependencies are specified in the `pom.xml` file.

## Testing

Unit tests are included in the `src/test/java/com/example/IngestServiceApplicationTests.java` file. You can run the tests using:

```
mvn test
```

## License

This project is licensed under the MIT License. See the LICENSE file for more details.