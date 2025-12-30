# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
# We create a temporary requirements.txt if one doesn't exist, but best practice is to have one.
RUN pip install --no-cache-dir flask gunicorn

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV APP_COLOR=blue
ENV APP_VERSION=1.0

# Run app.py when the container launches using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
