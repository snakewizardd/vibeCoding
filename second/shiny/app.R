# app.R
library(shiny)
library(leaflet) # Need the leaflet package
library(dplyr)   # Useful for data manipulation if needed
library(purrr)   # Useful for list manipulation

# Define a list of symbolic/interesting locations as named lists with facts
# Each list item contains numeric lat/lng, a character label, and a facts string
# Updated locations for more "based" content
symbolic_locations <- list(
  list(
    lat = 37.23649, lng = -115.80768, label = "Area 51, USA",
    facts = "AREA 51, USA\n\nKnown for intense government secrecy.\nWhispers of recovered extraterrestrial technology and life.\nA focal point for theories about advanced knowledge hidden from the public.\nConsidered by some as ground zero for classified future tech development."
  ),
  list(
    lat = 29.97648, lng = 31.13576, label = "Pyramids of Giza, Egypt",
    facts = "PYRAMIDS OF GIZA, EGYPT\n\nMonuments of incredible precision and scale from antiquity.\nConstruction methods still debated, hinting at lost knowledge or unknown aid.\nAligned with celestial bodies, suggesting advanced astronomical understanding.\nSymbolizes ancient power and mysteries that defy simple explanation."
  ),
  list(
    lat = -14.7464, lng = -75.1351, label = "Nazca Lines, Peru",
    facts = "NAZCA LINES, PERU\n\nVast geoglyphs etched into the desert floor, visible mainly from high above.\nPurpose remains unknown - ancient rituals, astronomy, or communication?\nSuggests a perspective or technology not typical of the time period.\nA mystery etched into the earth, waiting to be fully decoded."
  ),
  list(
    lat = 53.1567, lng = 107.6064, label = "Lake Baikal, Russia",
    facts = "LAKE BAIKAL, RUSSIA\n\nDeepest freshwater lake in the world, holding vast, unique biodiversity.\nIsolated ecosystem, potentially hiding undiscovered life forms.\nSubject of local legends about mysterious phenomena and unknown depths.\nA vast, dark, unexplored volume on the planet's surface."
  ),
  list(
    lat = 31.0667, lng = 81.3167, label = "Mount Kailash, Tibet",
    facts = "MOUNT KAILASH, TIBET\n\nSacred mountain across multiple religions, believed to be the axis mundi (center of the world).\nForbidden to climb, preserving its natural and possibly metaphysical state.\nStories of unusual energy and phenomena surrounding the peak.\nRepresents a spiritual or energetic focal point of the planet."
  ),
  list(
    lat = 33.3941, lng = -104.5150, label = "Roswell, New Mexico, USA",
    facts = "ROSWEL L, NEW MEXICO, USA\n\nSite of the infamous 1947 incident involving a crashed object.\nOfficial explanation versus persistent claims of an extraterrestrial craft and cover-up.\nSymbolizes the potential for contact and the withholding of world-altering truth.\nA key location in the narrative of hidden reality."
  ),
  list(
    lat = 78.2333, lng = 15.4667, label = "Svalbard Global Seed Vault, Norway",
    facts = "SVALBARD GLOBAL SEED VAULT, NORWAY\n\nA secure backup facility for crop diversity, buried deep within a mountain.\nA 'doomsday' vault, designed for survival after global catastrophe.\nRepresents humanity's collective attempt to preserve knowledge/resources for an uncertain future.\nA practical, yet symbolic, preparation for singularity-level disruption."
  ),
  list(
    lat = 46.2339, lng = 6.0545, label = "CERN, Switzerland",
    facts = "CERN, SWITZERLAND\n\nHome to the Large Hadron Collider, probing the fundamental nature of the universe.\nScientists seek to understand the building blocks of reality and recreate early cosmic conditions.\nExperiments push the boundaries of known physics, with potential for unforeseen discoveries.\nA place where reality itself is being explored and potentially manipulated."
  ),
  list(
    lat = -89.9999, lng = 0.0, label = "South Pole, Antarctica",
    facts = "SOUTH POLE, ANTARCTICA\n\nOne of the most remote and extreme environments on Earth.\nA hub for scientific research, including astrophysics and glaciology.\nThe vast, unexplored ice sheet may hide ancient secrets or anomalous structures.\nRepresents a frontier of isolation and potential discovery."
  ),
  list(
    lat = -27.11274, lng = -109.34997, label = "Easter Island",
    facts = "EASTER ISLAND\n\nIsolated island known for its mysterious Moai statues.\nThe story of its civilization's collapse serves as a warning about resource management.\nThe purpose and transport of the Moai remain subjects of debate and wonder.\nA symbol of ancient mysteries and the fragility of civilization."
  ),
  # Added new "based" locations
  list(
    lat = 32.3078, lng = -64.7505, label = "Bermuda Triangle",
    facts = "BERMUDA TRIANGLE\n\nRegion notorious for the mysterious disappearance of ships and aircraft.\nTheories range from geomagnetic anomalies to paranormal or extraterrestrial activity.\nA zone where conventional explanations often fail.\nRepresents a patch of Earth where reality seems less predictable."
  ),
  list(
    lat = -77.0000, lng = 105.0000, label = "Vostok Station, Antarctica (Lake Vostok)",
    facts = "VOSTOK STATION, ANTARCTICA (Lake Vostok)\n\nLocated above Lake Vostok, a vast subglacial lake hidden for millions of years.\nThis isolated ecosystem may harbor life forms unknown to science.\nA natural laboratory for extremophiles and a potential time capsule.\nHints at hidden environments and life beneath seemingly barren surfaces."
  ),
  list(
    lat = 37.223056, lng = 38.922778, label = "Gobekli Tepe, Turkey",
    facts = "GOBEKLI TEPE, TURKEY\n\nAncient archaeological site with megalithic structures predating known civilization by millennia.\nBuilt by hunter-gatherers, challenging assumptions about early human capabilities.\nSophistication suggests advanced knowledge or communication existed unexpectedly early.\nA monumental mystery reshaping understanding of history."
  ),
  list(
    lat = 19.6856, lng = -98.8439, label = "Teotihuacan, Mexico",
    facts = "TEOTIHUACAN, MEXICO\n\nLarge ancient Mesoamerican city with monumental pyramids and precise urban planning.\nCity's original name, inhabitants, and reasons for collapse remain unknown.\nAlignments and scale suggest advanced astronomical knowledge or symbolic purpose.\nA silent, imposing ruin holding secrets of a forgotten era."
  ),
  list(
    lat = 40.2669, lng = -109.8885, label = "Skinwalker Ranch, Utah, USA",
    facts = "SKINWALKER RANCH, UTAH, USA\n\nA site with a high frequency of unexplained phenomena: UFOs, cryptids, cattle mutilations, and strange energies.\nFocus of scientific and paranormal investigation for decades.\nMay represent a nexus point for interdimensional activity or unknown physical forces.\nA concentrated area of high strangeness."
  )
)

# Trippy messages (original list)
trippy_messages <- c(
  "Reality is an illusion, the universe is a hologram.",
  "Stay Weird.",
  "Embrace the chaos.",
  "Did you bring the snacks?",
  "Question everything.",
  "Sending good vibes.",
  "Synchronicity incoming.",
  "You are here.",
  "What is real?",
  "Look within.",
  "The code is sentient.",
  "Loading alternate timeline...",
  "Access granted: Unknown dimension.",
  "Processing paradox...",
  "Singularity imminent.",
  "The answer is 42... or is it?",
  "Decoding reality.",
  "Searching for signal..."
)


# Define UI using htmlTemplate
# This version still uses the same template file structure,
# but the template itself now handles responsiveness and the new viz.
ui <- htmlTemplate(
  filename = "www/template.html", # Path to the custom HTML template
  # Pass Shiny output elements to the template
  currentTime = textOutput("currentTime"),
  trippyMessage = textOutput("trippyMessage"),
  locationInfo = uiOutput("locationInfo"), # Use uiOutput for richer HTML content
  secondaryVisualization = uiOutput("secondaryVisualization"), # Use uiOutput for facts
  map = leafletOutput("map") # Placeholder for the Leaflet map
  # No new placeholder needed in app.R for the Network Viz, it's handled in JS/HTML
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive value to hold the current trippy message
  currentMessageRv <- reactiveVal("")
  # Store the selected location list item directly (now includes facts)
  currentLocationRv <- reactiveVal(list(lat = 0, lng = 0, label = "Initializing...", facts = "Awaiting transmission..."))
  
  # Update the time every 1 second
  output$currentTime <- renderText({
    invalidateLater(1000, session) # Re-run every 1000ms (1 second)
    as.character(Sys.time())
  })
  
  # Update the trippy message and select a new location every 10 seconds
  observe({
    # SLOWED DOWN: Re-run every 10000ms (10 seconds)
    invalidateLater(10000, session)
    
    # Update the reactive value with a random message
    currentMessageRv(sample(trippy_messages, 1))
    
    # Select and update the reactive value for the location (now includes facts)
    selected_location <- sample(symbolic_locations, 1)[[1]]
    currentLocationRv(selected_location)
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
  
  
  # Render the secondary visualization (Location Facts)
  output$secondaryVisualization <- renderUI({
    loc <- currentLocationRv() # Reacts when currentLocationRv changes
    
    # Display the facts using tags$pre to preserve line breaks
    # Add a simple header
    tags$div(
      tags$p("LOCATION INTEL:", style="font-weight: bold; text-align: center; margin-bottom: 5px;"),
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
  
  # Observe changes in the current location reactive value
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
        popup = paste("Destination:", loc$label) # Add a popup with the location label
      ) %>%
      # Pan the map to the new location smoothly
      setView(
        lng = loc$lng,
        lat = loc$lat,
        zoom = 6, # Zoom in a bit on the location
        options = list(
          animate = TRUE,
          duration = 5 # Increased map animation duration slightly to match slower update
        )
      )
  })
  
}

# Run the application
shinyApp(ui = ui, server = server)
