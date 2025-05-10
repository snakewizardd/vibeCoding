docker build -t whole_app .

docker run -d \            
  --name retrojournal-monolith-container \
  -p 8080:80 \
  -v retrojournal_db_data:/var/lib/postgresql/data \
  whole_app
