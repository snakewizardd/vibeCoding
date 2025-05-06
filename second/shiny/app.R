# app.R
library(shiny)
library(leaflet) # Need the leaflet package
library(dplyr)   # Useful for data manipulation if needed
library(purrr)   # Useful for list manipulation

# Define a list of symbolic/interesting locations as named lists with facts and anomaly values
# Each list item contains numeric lat/lng, a character label, a facts string, and an anomaly value
symbolic_locations <- list(
  list(
    lat = 37.23649, lng = -115.80768, label = "Area 51, USA", anomaly = 98.6,
    facts = "AREA 51, USA\n\nKnown for intense government secrecy.\nWhispers of recovered extraterrestrial technology and life.\nA focal point for theories about advanced knowledge hidden from the public.\nConsidered by some as ground zero for classified future tech development."
  ),
  list(
    lat = 29.97648, lng = 31.13576, label = "Pyramids of Giza, Egypt", anomaly = 85.3,
    facts = "PYRAMIDS OF GIZA, EGYPT\n\nMonuments of incredible precision and scale from antiquity.\nConstruction methods still debated, hinting at lost knowledge or unknown aid.\nAligned with celestial bodies, suggesting advanced astronomical understanding.\nSymbolizes ancient power and mysteries that defy simple explanation."
  ),
  list(
    lat = -14.7464, lng = -75.1351, label = "Nazca Lines, Peru", anomaly = 91.1,
    facts = "NAZCA LINES, PERU\n\nVast geoglyphs etched into the desert floor, visible mainly from high above.\nPurpose remains unknown - ancient rituals, astronomy, or communication?\nSuggests a perspective or technology not typical of the time period.\nA mystery etched into the earth, waiting to be fully decoded."
  ),
  list(
    lat = 53.1567, lng = 107.6064, label = "Lake Baikal, Russia", anomaly = 79.5,
    facts = "LAKE BAIKAL, RUSSIA\n\nDeepest freshwater lake in the world, holding vast, unique biodiversity.\nIsolated ecosystem, potentially hiding undiscovered life forms.\nSubject of local legends about mysterious phenomena and unknown depths.\nA vast, dark, unexplored volume on the planet's surface."
  ),
  list(
    lat = 31.0667, lng = 81.3167, label = "Mount Kailash, Tibet", anomaly = 88.9,
    facts = "MOUNT KAILASH, TIBET\n\nSacred mountain across multiple religions, believed to be the axis mundi (center of the world).\nForbidden to climb, preserving its natural and possibly metaphysical state.\nStories of unusual energy and phenomena surrounding the peak.\nRepresents a spiritual or energetic focal point of the planet."
  ),
  list(
    lat = 33.3941, lng = -104.5150, label = "Roswell, New Mexico, USA", anomaly = 99.9,
    facts = "ROSWEL L, NEW MEXICO, USA\n\nSite of the infamous 1947 incident involving a crashed object.\nOfficial explanation versus persistent claims of an extraterrestrial craft and cover-up.\nSymbolizes the potential for contact and the withholding of world-altering truth.\nA key location in the narrative of hidden reality."
  ),
  list(
    lat = 78.2333, lng = 15.4667, label = "Svalbard Global Seed Vault, Norway", anomaly = 65.0,
    facts = "SVALBARD GLOBAL SEED VAULT, NORWAY\n\nA secure backup facility for crop diversity, buried deep within a mountain.\nA 'doomsday' vault, designed for survival after global catastrophe.\nRepresents humanity's collective attempt to preserve knowledge/resources for an uncertain future.\nA practical, yet symbolic, preparation for singularity-level disruption."
  ),
  list(
    lat = 46.2339, lng = 6.0545, label = "CERN, Switzerland", anomaly = 95.7,
    facts = "CERN, SWITZERLAND\n\nHome to the Large Hadron Collider, probing the fundamental nature of the universe.\nScientists seek to understand the building blocks of reality and recreate early cosmic conditions.\nExperiments push the boundaries of known physics, with potential for unforeseen discoveries.\nA place where reality itself is being explored and potentially manipulated."
  ),
  list(
    lat = -89.9999, lng = 0.0, label = "South Pole, Antarctica", anomaly = 82.1,
    facts = "SOUTH POLE, ANTARCTICA\n\nOne of the most remote and extreme environments on Earth.\nA hub for scientific research, including astrophysics and glaciology.\nThe vast, unexplored ice sheet may hide ancient secrets or anomalous structures.\nRepresents a frontier of isolation and potential discovery."
  ),
  list(
    lat = -27.11274, lng = -109.34997, label = "Easter Island", anomaly = 77.0,
    facts = "EASTER ISLAND\n\nIsolated island known for its mysterious Moai statues.\nThe story of its civilization's collapse serves as a warning about resource management.\nThe purpose and transport of the Moai remain subjects of debate and wonder.\nA symbol of ancient mysteries and the fragility of civilization."
  ),
  list(
    lat = 32.3078, lng = -64.7505, label = "Bermuda Triangle", anomaly = 94.4,
    facts = "BERMUDA TRIANGLE\n\nRegion notorious for the mysterious disappearance of ships and aircraft.\nTheories range from geomagnetic anomalies to paranormal or extraterrestrial activity.\nA zone where conventional explanations often fail.\nRepresents a patch of Earth where reality seems less predictable."
  ),
  list(
    lat = -77.0000, lng = 105.0000, label = "Vostok Station, Antarctica (Lake Vostok)", anomaly = 89.0,
    facts = "VOSTOK STATION, ANTARCTICA (Lake Vostok)\n\nLocated above Lake Vostok, a vast subglacial lake hidden for millions of years.\nThis isolated ecosystem may harbor life forms unknown to science.\nA natural laboratory for extremophiles and a potential time capsule.\nHints at hidden environments and life beneath seemingly barren surfaces."
  ),
  list(
    lat = 37.223056, lng = 38.922778, label = "Gobekli Tepe, Turkey", anomaly = 96.2,
    facts = "GOBEKLI TEPE, TURKEY\n\nAncient archaeological site with megalithic structures predating known civilization by millennia.\nBuilt by hunter-gatherers, challenging assumptions about early human capabilities.\nSophistication suggests advanced knowledge or communication existed unexpectedly early.\nA monumental mystery reshaping understanding of history."
  ),
  list(
    lat = 19.6856, lng = -98.8439, label = "Teotihuacan, Mexico", anomaly = 87.6,
    facts = "TEOTIHUACAN, MEXICO\n\nLarge ancient Mesoamerican city with monumental pyramids and precise urban planning.\nCity's original name, inhabitants, and reasons for collapse remain unknown.\nAlignments and scale suggest advanced astronomical knowledge or symbolic purpose.\nA silent, imposing ruin holding secrets of a forgotten era."
  ),
  list(
    lat = 40.2669, lng = -109.8885, label = "Skinwalker Ranch, Utah, USA", anomaly = 97.3,
    facts = "SKINWALKER RANCH, UTAH, USA\n\nA site with a high frequency of unexplained phenomena: UFOs, cryptids, cattle mutilations, and strange energies.\nFocus of scientific and paranormal investigation for decades.\nMay represent a nexus point for interdimensional activity or unknown physical forces.\nA concentrated area of high strangeness."
  )
)

# Trippy messages
trippy_messages <- c(
  "REALITY IS AN ILLUSION, THE UNIVERSE IS A HOLOGRAM.",
  "STAY WEIRD.",
  "EMBRACE THE CHAOS.",
  "DID YOU BRING THE SNACKS?",
  "QUESTION EVERYTHING.",
  "SENDING GOOD VIBES.",
  "SYNCHRONICITY INCOMING.",
  "YOU ARE HERE.",
  "WHAT IS REAL?",
  "LOOK WITHIN.",
  "THE CODE IS SENTIENT.",
  "LOADING ALTERNATE TIMELINE...",
  "ACCESS GRANTED: UNKNOWN DIMENSION.",
  "PROCESSING PARADOX...",
  "SINGULARITY IMMINENT.",
  "THE ANSWER IS 42... OR IS IT?",
  "DECODING REALITY.",
  "SEARCHING FOR SIGNAL..."
)


# Define UI using htmlTemplate
ui <- htmlTemplate(
  filename = "www/template.html", # Path to the custom HTML template
  # Pass Shiny output elements to the template
  currentTime = textOutput("currentTime"),
  trippyMessage = textOutput("trippyMessage"),
  locationInfo = uiOutput("locationInfo"), # Use uiOutput for richer HTML content
  anomalyLevel = textOutput("anomalyLevel"), # New output for anomaly level
  secondaryVisualization = uiOutput("secondaryVisualization"), # Use uiOutput for facts
  map = leafletOutput("map") # Placeholder for the Leaflet map
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive value to hold the current trippy message
  currentMessageRv <- reactiveVal("")
  # Store the selected location list item directly (now includes facts and anomaly)
  currentLocationRv <- reactiveVal(list(lat = 0, lng = 0, label = "Initializing...", facts = "Awaiting transmission...", anomaly = 0))
  
  # Reactive value for the anomaly level
  anomalyLevelRv <- reactiveVal(0)
  
  
  # --- Initial Setup ---
  # Select initial location and message when the session starts
  selected_location <- sample(symbolic_locations, 1)[[1]]
  currentLocationRv(selected_location)
  anomalyLevelRv(selected_location$anomaly)
  currentMessageRv(sample(trippy_messages, 1))
  # --- End Initial Setup ---
  
  
  # Update the time every 1 second
  output$currentTime <- renderText({
    invalidateLater(1000, session) # Re-run every 1000ms (1 second)
    as.character(Sys.time())
  })
  
  # Update the trippy message, select a new location, and update anomaly every 10 seconds
  observe({
    # Re-run every 10000ms (10 seconds)
    invalidateLater(10000, session)
    
    # Update the reactive value with a random message
    currentMessageRv(sample(trippy_messages, 1))
    
    # Select and update the reactive value for the location (now includes facts and anomaly)
    selected_location <- sample(symbolic_locations, 1)[[1]]
    currentLocationRv(selected_location) # Trigger location update observers
    
    # Update anomaly level explicitly
    anomalyLevelRv(selected_location$anomaly)
  })
  
  # Render the trippy message to the UI placeholder
  output$trippyMessage <- renderText({
    currentMessageRv() # Display the current value of the reactive value
  })
  
  # Render the location information (coordinates and label)
  output$locationInfo <- renderUI({
    loc <- currentLocationRv() # Reacts when currentLocationRv changes
    tags$div( # Use tags to build HTML structure
      tags$p("TARGET COORDINATES:"),
      tags$p(paste("LAT:", round(loc$lat, 4), "LNG:", round(loc$lng, 4))),
      tags$p("LOCATION DESIGNATION:"),
      tags$p(loc$label)
    )
  })
  
  # Render the anomaly level
  output$anomalyLevel <- renderText({
    anomalyLevelRv() # Reacts when anomalyLevelRv changes
    paste("ANOMALY LEVEL:", round(anomalyLevelRv(), 1), "%") # Display with percentage
  })
  
  
  # Render the secondary visualization (Location Facts)
  output$secondaryVisualization <- renderUI({
    loc <- currentLocationRv() # Reacts when currentLocationRv changes
    
    # Display the facts using tags$pre to preserve line breaks
    tags$div(
      tags$p("LOCATION INTEL:", style="font-weight: bold; text-align: center; margin-bottom: 5px; color: #00cc00;"),
      tags$pre(loc$facts) # Display the facts string
    )
  })
  
  
  # --- Leaflet Map Logic ---
  
  # Render the initial map
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(options = providerTileOptions(noWrap = TRUE)) %>% # Add default tiles, prevent wrapping
      setView(lng = 0, lat = 0, zoom = 2) # Start centered on the world
  })
  
  # Observe changes in the current location reactive value (from auto-update or marker click)
  # When the location changes, move the map and update markers
  observeEvent(currentLocationRv(), {
    # Get the current location info from the reactive value
    loc <- currentLocationRv()
    
    # Use leafletProxy to update the map without redrawing it
    leafletProxy("map", session) %>%
      # Clear previous markers and add a new one at the target location
      clearMarkers() %>%
      addMarkers(
        lng = loc$lng,
        lat = loc$lat,
        popup = paste("Destination:", loc$label), # Add a popup with the location label
        layerId = loc$label # Assign a layerId to the marker for click detection
      ) %>%
      # Pan the map to the new location smoothly
      setView(
        lng = loc$lng,
        lat = loc$lat,
        zoom = 6, # Zoom in a bit on the location
        options = list(
          animate = TRUE,
          duration = 2 # Animation duration
        )
      )
  })
  
  # --- Interaction Logic ---
  
  # Observe clicks on map markers - just update location and anomaly
  observeEvent(input$map_marker_click, {
    click <- input$map_marker_click
    
    # Find the location in our list that matches the clicked marker's ID (label)
    clicked_loc <- symbolic_locations %>%
      purrr::keep(~ .x$label == click$id) %>%
      purrr::pluck(1, .default = NULL) # Get the first match, or NULL if none
    
    if (!is.null(clicked_loc)) {
      # Update location and anomaly immediately to the clicked one
      currentLocationRv(clicked_loc)
      anomalyLevelRv(clicked_loc$anomaly)
      # Note: Auto-update observer is NOT req(!paused()), so it will continue cycling locations
      # after the marker click updates the current location.
    }
  })
  
  # Removed the pause button observer and the state observer
  
}

# Run the application
shinyApp(ui = ui, server = server)