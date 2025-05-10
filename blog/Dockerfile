# Use a base image that has system tools and is suitable for multiple applications
FROM ubuntu:22.04

# Set environment variables to make apt-get non-interactive and set a default timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC  

# Install system dependencies: Python, pip, PostgreSQL, Nginx, Supervisor
# The DEBIAN_FRONTEND env var set above should prevent the tzdata prompt now
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    postgresql postgresql-contrib \
    nginx \
    supervisor \
    tzdata \ 
    && rm -rf /var/lib/apt/lists/*

# --- Configure Python/FastAPI Backend ---
WORKDIR /app

# Use python3 as the default python
RUN ln -s /usr/bin/python3 /usr/local/bin/python \
    && ln -s /usr/bin/pip3 /usr/local/bin/pip

# Copy requirements and install Python dependencies
COPY ./backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt gunicorn # Add gunicorn for production server

# Copy your backend code
COPY ./backend/app /app/app

# --- Configure PostgreSQL Database ---
# Initialize PostgreSQL data directory
# NOTE: Data will NOT be persistent unless a volume is mounted to /var/lib/postgresql/data externally
RUN chown -R postgres:postgres /var/lib/postgresql \
    && chmod -R 700 /var/lib/postgresql \
    && su postgres -c "/usr/lib/postgresql/14/bin/pg_ctl initdb -D /var/lib/postgresql/data" # Use full path here

# Configure PostgreSQL authentication (simple trust for this example, NOT secure)
# In a real scenario, you'd use environment variables and more secure methods
# Make sure the Postgres version matches the installed one (e.g., 14)
RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/14/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf

# Set up DB environment variables for the app (passed via Supervisor config)
ENV POSTGRES_USER user
ENV POSTGRES_PASSWORD password
ENV POSTGRES_DB retro_journal_db
# DB_HOST will be 'localhost' or '127.0.0.1' because it's in the same container
ENV DB_HOST 127.0.0.1
ENV DB_PORT 5432

# --- Configure Nginx Frontend ---
# Remove default Nginx config
RUN rm /etc/nginx/sites-enabled/default

# Copy frontend static files
COPY ./frontend /var/www/html

# Create Nginx configuration for static files and backend proxy
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /var/www/html; \
    index index.html; \
\
    # Serve static files directly \
    location / { \
        try_files $uri $uri/ =404; \
    } \
\
    # Proxy API requests to the backend (running on port 8000 internally) \
    location /api { \
        proxy_pass http://127.0.0.1:8000; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
}' > /etc/nginx/sites-available/retrojournal
RUN ln -s /etc/nginx/sites-available/retrojournal /etc/nginx/sites-enabled/

# --- Configure Supervisor to manage processes ---
RUN mkdir -p /var/log/supervisor

# COPY the supervisord.conf file from your local directory into the image
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the port Nginx is listening on
EXPOSE 80

# CMD no longer runs supervisor directly; instead, it executes the entrypoint.sh script
CMD ["/usr/local/bin/entrypoint.sh"]