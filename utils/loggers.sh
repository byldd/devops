# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions with timestamps and colors
log_info() {
    echo -e "${BLUE}-> ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✖ $1${NC}"
}

# Spinner animation for showing progress
show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        for ((i = 0; i < ${#spinstr}; i++)); do
            printf "\r⏳ %s [%c] " "$message" "${spinstr:i:1}"
            sleep $delay
        done
    done
    printf "\r%*s\r" "$(tput cols)" "" # clear line cleanly
}
