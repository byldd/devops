install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="/tmp/${name,,}_install_error.log"

  echo -n "✨ Step : Configuring $name"
  if $command_fn check &>/dev/null; then
    echo -n "✔️ $name is already installed"
    return
  else
    echo -n "⏳ Installing $name"
  fi

  # Run install in background subshell
  (
    set -e
    $command_fn install > /dev/null 2> "$error_log"
  ) &
  local pid=$!

  # Print clean progress dots
  while kill -0 "$pid" 2>/dev/null; do
    echo -n "."
    sleep 0.5
  done

  # Print newline after progress
  echo

  # Handle completion
  if wait $pid; then
    echo "✔️ $name installation completed."
    rm -f "$error_log"
  else
    echo "❌  $name installation failed!"
    echo "🔧  Error output:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi
}
