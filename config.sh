# Configuration Settings

# Emoji Preferences
EMOJI_PREFERENCE="😊"

# Default Values
DEFAULT_TIMEOUT=30
DEFAULT_RETRIES=5

# Dependencies Check
REQUIRED_DEPENDENCIES=("curl" "wget")

function check_dependencies() {
    for dep in "${REQUIRED_DEPENDENCIES[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo "$dep is not installed. Please install it to continue."
            exit 1
        fi
    done
}

# Run the dependency check
check_dependencies
