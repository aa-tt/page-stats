# docker build -t ianunay/ingest:v0 .
# Use an official OpenJDK runtime as a parent image
FROM openjdk:11-jre-slim

# Set the working directory in the container
WORKDIR /app

# Copy the packaged jar file into the container
COPY target/ingest-service-0.0.1-SNAPSHOT.jar /app/ingest-service.jar

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Run the jar file
ENTRYPOINT ["java", "-jar", "ingest-service.jar"]