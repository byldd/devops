install_with_progress() {
  local name=$1
  local command_fn=$2
  local error_log="/tmp/${name,,}_install_error.log"

  echo -n "🔍  Checking if $name is already installed... "
  if $command_fn check &>/dev/null; then
    echo "✅  $name is already installed."
    return
  else
    echo "⏳  Not found. Installing $name..."
  fi

  # Run the install in a clean background subshell
  (
    set -e
    $command_fn install > /dev/null 2> "$error_log"
  ) &
  local pid=$!

  # Show progress dots while installing
  local i=0
  local dots=""
  while kill -0 "$pid" 2>/dev/null; do
    dots="${dots}."
    echo -ne "\r🚀  Installing $name$dots"
    sleep 0.5
    i=$((i + 1))
    if [ $i -eq 6 ]; then
      dots=""
      i=0
    fi
  done
  echo -ne "\r"

  # Wait for completion and handle result
  if wait $pid; then
    echo "✅  $name installation completed."
    rm -f "$error_log"
  else
    echo "❌  $name installation failed!"
    echo "🔧  Error output:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi
}
