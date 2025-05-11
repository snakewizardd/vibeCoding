import requests
import json
import sys # To exit with status code
import time # Optional: for adding delays

# --- Configuration ---
# The actual API endpoint URL for creating entries (based on your docs URL)
API_URL = "http://localhost:8001/api/entries"
API_URL = "https://vibecoding.onrender.com/api/entries"
# The path to your JSON file containing the list of entries
INPUT_JSON_FILE = "gemini_mindfulness.json"
# Optional: Add a small delay between requests (in seconds)
REQUEST_DELAY_SECONDS = 0.1 # e.g., 0.1 for 100ms, 1.0 for 1 second

# --- Function to Read JSON File ---
def load_entries_from_json(filepath):
    """Reads a list of journal entry dictionaries from a JSON file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            if not isinstance(data, list):
                print(f"Error: JSON file '{filepath}' does not contain a list at the top level.", file=sys.stderr)
                return None
            print(f"Successfully loaded {len(data)} potential entries from '{filepath}'.")
            return data
    except FileNotFoundError:
        print(f"Error: Input JSON file not found at '{filepath}'", file=sys.stderr)
        return None
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from '{filepath}'. Check file format and ensure it's valid JSON.", file=sys.stderr)
        return None
    except Exception as e:
        print(f"An unexpected error occurred while reading file: {e}", file=sys.stderr)
        return None

# --- Function to Post Single Entry ---
def post_journal_entry(url, entry_data):
    """Posts a single journal entry dictionary to the API endpoint."""
    # Ensure the entry_data is a dictionary and has the required keys
    if not isinstance(entry_data, dict):
         print(f"Skipping invalid entry data (not a dictionary): {entry_data}", file=sys.stderr)
         return False
    if 'title' not in entry_data or 'content' not in entry_data:
         print(f"Skipping entry missing 'title' or 'content': {entry_data}", file=sys.stderr)
         return False

    headers = {
        'Content-Type': 'application/json'
    }
    title_preview = entry_data.get('title', 'Untitled Entry')[:50] + '...' if len(entry_data.get('title', 'Untitled Entry')) > 50 else entry_data.get('title', 'Untitled Entry')

    try:
        # Using json= automatically serializes the dictionary to JSON and sets Content-Type
        response = requests.post(url, headers=headers, json=entry_data)

        # Check for successful status codes (200 OK, 201 Created)
        if response.status_code in [200, 201]:
            print(f"  SUCCESS: Posted '{title_preview}' (Status: {response.status_code})")
            # Optional: print response data if helpful
            # try:
            #     print(f"    Response body: {response.json()}")
            # except json.JSONDecodeError:
            #     print(f"    Response body (not JSON): {response.text}")
            return True
        else:
            print(f"  FAILURE: Failed to post '{title_preview}' (Status: {response.status_code})", file=sys.stderr)
            try:
                # Attempt to print error details from the response body
                print(f"    Response body: {response.json()}", file=sys.stderr)
            except json.JSONDecodeError:
                print(f"    Response body (not JSON): {response.text}", file=sys.stderr) # Fallback
            return False

    except requests.exceptions.ConnectionError as e:
         print(f"  ERROR: Connection failed for '{title_preview}'. Is the API running at {url}?", file=sys.stderr)
         print(f"    Details: {e}", file=sys.stderr)
         return False
    except requests.exceptions.Timeout:
         print(f"  ERROR: Request timed out for '{title_preview}'.", file=sys.stderr)
         return False
    except requests.exceptions.RequestException as e:
        print(f"  ERROR: An error occurred during request for '{title_preview}': {e}", file=sys.stderr)
        return False
    except Exception as e:
         print(f"  ERROR: An unexpected error occurred during post attempt for '{title_preview}': {e}", file=sys.stderr)
         return False


# --- Main Execution ---
if __name__ == "__main__":
    print(f"Starting script to post journal entries...")
    print(f"API Endpoint: {API_URL}")
    print(f"Input File: {INPUT_JSON_FILE}\n")

    all_entries = load_entries_from_json(INPUT_JSON_FILE)

    if all_entries is None:
        # load_entries_from_json already prints the error
        sys.exit(1) # Exit with an error code if file loading failed

    if not all_entries:
        print("No entries found in the JSON file after loading. Nothing to post.")
        sys.exit(0) # Exit successfully but nothing was done

    print(f"Proceeding to post {len(all_entries)} entries...\n")

    successful_count = 0
    failed_count = 0
    skipped_count = 0 # Count items that weren't dicts or missing keys

    for i, entry in enumerate(all_entries):
        # Print which entry we're attempting
        entry_number = i + 1
        print(f"Attempting entry {entry_number}/{len(all_entries)}:")

        if not isinstance(entry, dict) or 'title' not in entry or 'content' not in entry:
            print(f"  SKIPPED: Entry {entry_number} is invalid (not dict or missing keys).", file=sys.stderr)
            skipped_count += 1
            failed_count += 1 # Treat skipped as a failure to post
            continue # Move to the next item in the list

        if post_journal_entry(API_URL, entry):
            successful_count += 1
        else:
            failed_count += 1

        # Optional: Add a delay after each request
        if REQUEST_DELAY_SECONDS > 0:
             time.sleep(REQUEST_DELAY_SECONDS)


    print("\n--- Posting Process Finished ---")
    print(f"Total entries in file: {len(all_entries)}")
    print(f"Successfully posted: {successful_count}")
    print(f"Failed to post (including skipped): {failed_count}")

    if failed_count > 0:
        sys.exit(1) # Exit with an error code if any posts failed
    else:
        sys.exit(0) # Exit successfully