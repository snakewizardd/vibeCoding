# app/main.py
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional # Optional is used for query params or optional fields
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import time

# --- Configuration & Global Variables ---
DB_NAME = os.getenv("POSTGRES_DB", "retro_journal_db")
DB_USER = os.getenv("POSTGRES_USER", "user")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "password")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")

# --- FastAPI App Instance ---
app = FastAPI(title="RetroJournal API")

# --- CORS Configuration ---
origins = [
    "http://localhost:8080", # Where our Nginx frontend will run
    "http://127.0.0.1:8080",
    "null", # Allow requests from file:// (local HTML file opened in browser)
    # Add other origins if necessary
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Pydantic Models ---
class JournalEntryBase(BaseModel):
    title: str
    content: str

class JournalEntryCreate(JournalEntryBase):
    pass

class JournalEntryUpdate(JournalEntryBase): # For PUT requests, fields might be optional
    title: Optional[str] = None
    content: Optional[str] = None

class JournalEntry(JournalEntryBase):
    id: int
    created_at: datetime
    updated_at: datetime # Added updated_at

    class Config:
        orm_mode = True # Pydantic v1
        # from_attributes = True # Pydantic v2

# --- Database Connection Helper ---
def get_db_connection():
    conn = None
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error connecting to database: {e}")
        # This error will be caught by endpoint exception handlers if it happens during a request
        # For init_db, it's handled separately.
        raise HTTPException(status_code=503, detail="Database connection unavailable")

# --- Database Initialization Function ---
def init_db():
    conn = None
    print("Attempting to initialize database...")
    # Retry mechanism for DB connection during initialization
    for i in range(5): # Try 5 times
        try:
            conn = psycopg2.connect(
                dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
            )
            print("Successfully connected to database for initialization.")
            break # Exit loop on successful connection
        except psycopg2.OperationalError as e:
            print(f"DB connection attempt {i+1} failed: {e}. Retrying in 3 seconds...")
            if i == 4: # Last attempt failed
                print("Could not connect to the database after multiple retries. Exiting initialization.")
                return # Exit init_db if connection fails repeatedly
            time.sleep(3)
    
    if not conn:
        return # Should not happen if loop logic is correct

    try:
        with conn.cursor() as cur:
            # Create journal_entries table
            cur.execute("""
                CREATE TABLE IF NOT EXISTS journal_entries (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    content TEXT NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print("Table 'journal_entries' checked/created.")

            # Create function to update 'updated_at'
            cur.execute("""
                CREATE OR REPLACE FUNCTION trigger_set_timestamp()
                RETURNS TRIGGER AS $$
                BEGIN
                  NEW.updated_at = NOW();
                  RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
            """)
            print("Function 'trigger_set_timestamp' created/updated.")

            # Create trigger to use the function (drop if exists to avoid error if definition changes)
            cur.execute("DROP TRIGGER IF EXISTS set_timestamp_trigger ON journal_entries;")
            cur.execute("""
                CREATE TRIGGER set_timestamp_trigger
                BEFORE UPDATE ON journal_entries
                FOR EACH ROW
                EXECUTE FUNCTION trigger_set_timestamp();
            """)
            print("Trigger 'set_timestamp_trigger' created on 'journal_entries'.")
            
            conn.commit()
        print("Database initialization complete.")
    except psycopg2.Error as e:
        print(f"Database error during initialization: {e}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"General error during DB initialization: {e}")
    finally:
        if conn:
            conn.close()
    print("Database initialization routine finished.")

# --- API Endpoints ---
@app.post("/api/entries", response_model=JournalEntry, status_code=status.HTTP_201_CREATED)
async def create_journal_entry(entry: JournalEntryCreate):
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "INSERT INTO journal_entries (title, content) VALUES (%s, %s) RETURNING id, title, content, created_at, updated_at",
                (entry.title, entry.content)
            )
            new_entry_data = cur.fetchone()
            conn.commit()
            if not new_entry_data:
                raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create journal entry")
            return JournalEntry(**new_entry_data)
    except psycopg2.Error as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")
    finally:
        if conn: conn.close()

@app.get("/api/entries", response_model=List[JournalEntry])
async def get_all_journal_entries(skip: int = 0, limit: int = 100): # Added pagination params
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "SELECT id, title, content, created_at, updated_at FROM journal_entries ORDER BY created_at DESC LIMIT %s OFFSET %s",
                (limit, skip)
            )
            entries_data = cur.fetchall()
            return [JournalEntry(**entry_data) for entry_data in entries_data]
    except psycopg2.Error as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")
    finally:
        if conn: conn.close()

@app.get("/api/entries/{entry_id}", response_model=JournalEntry)
async def get_journal_entry(entry_id: int):
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "SELECT id, title, content, created_at, updated_at FROM journal_entries WHERE id = %s",
                (entry_id,)
            )
            entry_data = cur.fetchone()
            if not entry_data:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found")
            return JournalEntry(**entry_data)
    except psycopg2.Error as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")
    finally:
        if conn: conn.close()

@app.put("/api/entries/{entry_id}", response_model=JournalEntry)
async def update_journal_entry(entry_id: int, entry_update: JournalEntryUpdate):
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # First, check if entry exists
            cur.execute("SELECT id FROM journal_entries WHERE id = %s", (entry_id,))
            if not cur.fetchone():
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found for update")

            # Build the update query dynamically based on provided fields
            # For simplicity, we'll assume title and content are always provided for an update here,
            # matching JournalEntryBase. If using JournalEntryUpdate with optional fields,
            # you'd build the SET clause dynamically.
            # For this example, using the fields from JournalEntryBase for simplicity.
            # Ensure title and content from entry_update are not None if they are optional.
            # Let's assume for now that title and content are required for an update for simplicity.
            # A more robust solution would check entry_update.title and entry_update.content.
            
            if entry_update.title is None or entry_update.content is None:
                 raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Title and content are required for update.")


            cur.execute(
                "UPDATE journal_entries SET title = %s, content = %s WHERE id = %s RETURNING id, title, content, created_at, updated_at",
                (entry_update.title, entry_update.content, entry_id)
            )
            updated_entry_data = cur.fetchone()
            conn.commit()
            if not updated_entry_data: # Should not happen if ID check passed and RETURNING is used
                raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update journal entry")
            return JournalEntry(**updated_entry_data)
    except psycopg2.Error as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")
    finally:
        if conn: conn.close()

@app.delete("/api/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_journal_entry(entry_id: int):
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("DELETE FROM journal_entries WHERE id = %s RETURNING id", (entry_id,))
            deleted_id = cur.fetchone()
            conn.commit()
            if not deleted_id:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found for deletion")
            # No content returned for 204
    except psycopg2.Error as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"An unexpected error occurred: {str(e)}")
    finally:
        if conn: conn.close()

@app.get("/")
async def root():
    return {"message": "RetroJournal API is running. Access /docs for API documentation."}

# --- Run DB Initialization on Startup ---
# @app.on_event("startup") # FastAPI's preferred way for async startup/shutdown
# async def startup_event():
# init_db() # Direct call, ensure it's robust or run in a separate script before starting app

init_db()