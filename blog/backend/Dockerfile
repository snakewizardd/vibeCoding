# backend/Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app /app/app

# Expose the port Uvicorn will run on
EXPOSE 8000

# Command to run the application
# The --host 0.0.0.0 makes it accessible from outside the container (i.e., from other Docker services or the host)
# --reload is for development, remove for production
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]