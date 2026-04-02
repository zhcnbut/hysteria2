#!/bin/bash

# Utility functions

# Validation Function
validate() {
    if [ -z "$1" ]; then
        echo "Error: Argument is required."
        return 1
    fi
}

# Logging Function
log() {
    local message="$1"
    echo "[LOG] $message"
}

# Networking Function
fetch_data() {
    local url="$1"
    response=$(curl -s "$url")
    echo "$response"
}

# Error Handling Function
handle_error() {
    local exit_code=$1
    if [ $exit_code -ne 0 ]; then
        echo "Error: Command failed with exit code $exit_code"
        exit $exit_code
    fi
}