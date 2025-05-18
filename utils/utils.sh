install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="${name,,}_install_error.log"

  echo -n "🚀  STEP : Configuring $name "
  if $command_fn check &>/dev/null; then
    echo "✔️  $name is already installed."
  fi

  # Start install in a subshell in the background
  (
    $command_fn install > /dev/null 2>"$error_log"
  ) &
  local pid=$!

  # Progress dots
  local dots=""
  while kill -0 "$pid" 2>/dev/null; do
    dots="$dots."
    echo -ne "\r⏳ Installing $name$dots"
    sleep 0.5
    [[ ${#dots} -ge 3 ]] && dots=""
  done
  echo -ne "\r"

  # Handle completion
  if wait $pid; then
    echo "✔️  $name installation completed."
    rm -f "$error_log"
  else
    echo "❌  $name installation failed!"
    echo "🔧  Error log:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi
}
