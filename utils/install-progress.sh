install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="/tmp/${name,,}_install_error.log"

  log_info "Setting up $name :"

  local is_exists=false

  if $command_fn check &>/dev/null; then
    log_success "$name is already installed."
    is_exists=true
  fi

  if [ "$is_exists" = false ]; then
    # Run install in background subshell
    (
      set -e
      $command_fn install >/dev/null 2>"$error_log"
    ) &
    local pid=$!

    # Show spinner while installing
    show_spinner "$pid" "Installing $name. This may take a few moments..."

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

  # Run configure in background subshell
  (
    set -e
    $command_fn configure >/dev/null 2>"$error_log"
  ) &
  local conf_pid=$!

  # Show spinner while configuring
  show_spinner "$conf_pid" "Configuring $name..."

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
