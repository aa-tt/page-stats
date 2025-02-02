# docker build -t ianunay/processor:v0 .
# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy the requirements.txt file
COPY requirements.txt /app/requirements.txt

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy your application code
COPY main.py /app/main.py

# Run the application
CMD ["python", "main.py"]