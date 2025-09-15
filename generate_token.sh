#!/bin/bash

# Token Generator Script for Storm MCP API
# Based on login API details from Postman collection "Storm mcp"

# Default configuration
API_URL="https://example.com/api/login"
USERNAME=""
PASSWORD=""
OUTPUT_FILE="token.txt"
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username USERNAME    Set the username for login"
    echo "  -p, --password PASSWORD    Set the password for login"
    echo "  -a, --api-url URL         Set the API URL (default: https://example.com/api/login)"
    echo "  -o, --output FILE         Output file for token (default: token.txt)"
    echo "  -v, --verbose             Enable verbose output"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -u myuser -p mypassword"
    echo "  $0 -u myuser -p mypassword -a https://api.storm.com/login"
    echo "  $0 -u myuser -p mypassword -o my_token.txt"
}

# Function to log messages
log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}[INFO]${NC} $1"
    fi
}

# Function to log errors
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to log success
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -a|--api-url)
            API_URL="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    log_error "Username and password are required"
    echo ""
    usage
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed. Please install curl and try again."
    exit 1
fi

log "Starting token generation process..."
log "API URL: $API_URL"
log "Username: $USERNAME"
log "Output file: $OUTPUT_FILE"

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF
)

log "Sending login request..."

# Make the API call
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "$API_URL")

# Extract HTTP status code and response body
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

log "HTTP Status Code: $HTTP_CODE"
log "Response: $RESPONSE_BODY"

# Check if the request was successful
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    # Try to extract token from response
    # Common token field names: token, access_token, accessToken, authToken, jwt
    TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$TOKEN" ]; then
        TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$TOKEN" ]; then
        TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$TOKEN" ]; then
        TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"authToken":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$TOKEN" ]; then
        TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"jwt":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -n "$TOKEN" ]; then
        # Save token to file
        echo "$TOKEN" > "$OUTPUT_FILE"
        log_success "Token generated and saved to $OUTPUT_FILE"
        echo ""
        echo "Token: $TOKEN"
        echo ""
        echo "You can use this token in subsequent API calls by including it in the Authorization header:"
        echo "Authorization: Bearer $TOKEN"
    else
        log_error "Login successful but no token found in response"
        log "Full response: $RESPONSE_BODY"
        exit 1
    fi
else
    log_error "Login failed with HTTP status code: $HTTP_CODE"
    log "Response: $RESPONSE_BODY"
    exit 1
fi
