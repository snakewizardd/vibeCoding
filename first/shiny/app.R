# app.R
library(shiny)

# Define UI using htmlTemplate
# This loads your custom HTML file and allows you to insert Shiny elements
ui <- htmlTemplate(
  filename = "www/template.html", # Specify the path to your custom HTML template
  # Map the names used in {{ }} in the HTML template to Shiny output elements
  # The 'currentTime' placeholder in the HTML will be filled by textOutput("currentTime")
  currentTime = textOutput("currentTime"),
  # The 'trippyMessage' placeholder in the HTML will be filled by textOutput("trippyMessage")
  trippyMessage = textOutput("trippyMessage")
)

# Define server logic required to render outputs
server <- function(input, output, session) {
  
  # Reactive output for the current time (updates every second)
  output$currentTime <- renderText({
    # Invalidate this reactive expression every 1000 milliseconds (1 second)
    invalidateLater(1000, session)
    # Get the current system time and convert it to a character string
    as.character(Sys.time())
  })
  
  # Reactive output for a trippy message (updates every 5 seconds)
  output$trippyMessage <- renderText({
    invalidateLater(5000, session) # Re-run this code every 5 seconds
    
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
      "Look within."
    )
    
    # Select a random message from the list
    sample(trippy_messages, 1)
  })
  
  # You can add more server-side logic here to handle inputs,
  # perform calculations, or generate other outputs if needed.
}

# Run the application
shinyApp(ui = ui, server = server)
