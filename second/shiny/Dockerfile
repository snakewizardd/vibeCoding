# Use a base image with R and Shiny pre-installed
FROM rocker/shiny:4.1.0

# Install necessary system libraries for spatial packages like 'terra' (though not used here, good practice for geospatial)
# Note: You may need to adjust these based on the specific base image and your needs.
# We include these as a general attempt to cover potential compiled dependencies.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcurl4-gnutls-dev \
    libssl-dev \
    libgdal-dev \
    libgeos-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages - these will be installed from CRAN by default
# The base image already has shiny, but explicitly listing all dependencies is clear.
RUN R -e "install.packages(c('leaflet', 'dplyr', 'purrr'), repos='http://cran.rstudio.com/')"

# Create an app directory in the container
RUN mkdir /app

# Copy the application code and the www directory into the container
COPY app.R /app/
COPY www /app/www/

# Set the working directory
WORKDIR /app

# Expose the Shiny port
EXPOSE 3838

# Command to run the Shiny application
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]

