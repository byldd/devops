SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
ENV_EXAMPLE_FILE="$SCRIPT_DIR/../.env.example"

log_info "Checking environment variables"

if [ ! -f "$ENV_FILE" ]; then
  log_error ".env not found."
  exit 1
fi

# Load .env values into the environment
set -a
source "$ENV_FILE" 2>/dev/null || true
set +a

missing_keys=()

# Read each required key from .env.example
while IFS= read -r line || [ -n "$line" ]; do
  # Skip comments and blank lines
  [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^# ]] && continue

  key=$(echo "$line" | cut -d '=' -f 1 | xargs)

  # Check if the key is set in the environment
  if [ -z "${!key+x}" ]; then
    missing_keys+=("$key")
  fi
done <"$ENV_EXAMPLE_FILE"

# If any keys are missing, report and exit
if [ ${#missing_keys[@]} -ne 0 ]; then
  log_error "Missing required environment variables:"
  for k in "${missing_keys[@]}"; do
    echo "   - $k"
  done
  exit 1
fi

if [[ "$WORKOS_ROLE_SYNC_ENABLED" != "true" && "$WORKOS_ROLE_SYNC_ENABLED" != "false" ]]; then
  log_error "WORKOS_ROLE_SYNC_ENABLED must be set to either 'true' or 'false'."
  exit 1
fi

log_success "Environment validation successful."
echo "--------------------------------"
echo
