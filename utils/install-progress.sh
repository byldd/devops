#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions with timestamps and colors
log_info() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}✔ $1${NC}"
}

log_warn() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}⚠ $1${NC}"
}

log_error() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}✖ $1${NC}"
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

# Main install_with_progress function
install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="/tmp/${name,,}_install_error.log"

  log_info "Starting configuration of $name..."

  local is_exists=false

  if $command_fn check &>/dev/null; then
    log_success "$name is already installed."
    is_exists=true
  fi

  if [ "$is_exists" = false ]; then
    log_info "Installing $name. This may take a few moments..."
    # Run install in background subshell
    (
      set -e
      $command_fn install >/dev/null 2>"$error_log"
    ) &
    local pid=$!

    # Show spinner while installing
    show_spinner "$pid" "Installing $name"

    if wait $pid; then
      log_success "$name installation completed successfully."
      rm -f "$error_log"
    else
      log_error "$name installation failed!"
      log_error "Error details:"
      cat "$error_log"
      rm -f "$error_log"
      exit 1
    fi
  fi

  log_info "Configuring $name..."

  # Run configure in background subshell
  (
    set -e
    $command_fn configure >/dev/null 2>"$error_log"
  ) &
  local conf_pid=$!

  # Show spinner while configuring
  show_spinner "$conf_pid" "Configuring $name"

  if wait $conf_pid; then
    log_success "$name configuration completed successfully."
    rm -f "$error_log"
    echo "-----------------------"
  else
    log_error "$name configuration failed!"
    log_error "Error details:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi

  echo
}
