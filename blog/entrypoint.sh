#!/bin/bash
set -e

# Start PostgreSQL in the background
echo "Starting PostgreSQL..."
su postgres -c "/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/data" &
POSTGRES_PID=$!

# Wait for PostgreSQL to be ready (using pg_isready)
echo "Waiting for PostgreSQL to be ready..."
until su postgres -c "/usr/lib/postgresql/14/bin/pg_isready -U postgres"; do
  echo "PostgreSQL is not yet ready. Sleeping..."
  sleep 2
done

echo "PostgreSQL is ready!"

# Create the 'user' role if it doesn't exist
echo "Creating the 'user' role..."
su postgres -c "psql -U postgres -d postgres -c \"CREATE ROLE \\\"user\\\" WITH LOGIN PASSWORD 'password';\"" || true  # Ignore error if it already exists

# Create the 'retro_journal_db' database if it doesn't exist
echo "Creating the 'retro_journal_db' database..."
su postgres -c "psql -U postgres -d postgres -c \"CREATE DATABASE retro_journal_db OWNER \\\"user\\\";\"" || true # Ignore error if it already exists

# Configure pg_hba.conf with the "trust" setting for the "user" role
echo "Configuring pg_hba.conf to trust local connections"
echo "host retro_journal_db user 127.0.0.1/32 trust" >> /etc/postgresql/14/main/pg_hba.conf

# Start supervisor
echo "Starting Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf