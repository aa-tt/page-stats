FROM continuumio/miniconda3

# Create a Conda environment and install necessary packages
RUN conda create -n consolidator python=3.8 && \
    conda install -n consolidator -c conda-forge pyspark influxdb-client psycopg2-binary curl openjdk=11 && \
    conda clean -a

# Activate the Conda environment
SHELL ["conda", "run", "-n", "consolidator", "/bin/bash", "-c"]

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/opt/conda/envs/consolidator

# Create directory for Spark jars
RUN mkdir -p /opt/spark/jars

# Download PostgreSQL JDBC driver using curl
RUN curl -o /opt/spark/jars/postgresql-42.2.23.jar https://jdbc.postgresql.org/download/postgresql-42.2.23.jar

# Set environment variable for Spark classpath
ENV SPARK_CLASSPATH="/opt/spark/jars/postgresql-42.2.23.jar"

# Copy the consolidator script
COPY consolidator.py /app/consolidator.py

# Set the working directory
WORKDIR /app

# Run the consolidator script
CMD ["conda", "run", "--no-capture-output", "-n", "consolidator", "python", "consolidator.py"]