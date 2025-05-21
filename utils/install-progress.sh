install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="/tmp/${name,,}_install_error.log"

  echo "✨ Step : Configuring $name"

  is_exists = false

  if $command_fn check &>/dev/null; then
    echo "✔️  $name is already installed"
    echo "-----------------------"
    echo
    is_exists = true
  fi

  if [ "$is_exists" = false ]; then
    echo "⏳ Installing $name"
    # Run install in background subshell
    (
      set -e
      $command_fn install >/dev/null 2>"$error_log"
    ) &
    local pid=$!

    # Progress
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
      echo "-----------------------"
    else
      echo "❌  $name installation failed!"
      echo "🔧  Error output:"
      cat "$error_log"
      rm -f "$error_log"
      exit 1
    fi
  fi

  echo "⏳ Configuring $name"

  # Run Configure in background subshell
  (
    set -e
    $command_fn configure >/dev/null 2>"$error_log"
  ) &
  local conf_pid=$!

  # Progress
  while kill -0 "$conf_pid" 2>/dev/null; do
    echo -n "."
    sleep 0.5
  done

  # Print newline after progress
  echo

  # Handle completion
  if wait $conf_pid; then
    echo "✔️ $name configuration completed."
    rm -f "$error_log"
    echo "-----------------------"
  else
    echo "❌  $name configuration failed!"
    echo "🔧  Error output:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi

  echo
}
