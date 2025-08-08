# Start from a Python base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /code

# Copy the requirements file and install dependencies
# This is done in a separate step to leverage Docker's layer caching.
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copy the application code into the container
COPY . /code

# Expose the port that the application will run on
EXPOSE 8000
