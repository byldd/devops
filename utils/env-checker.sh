ENV_EXAMPLE_FILE="../.env.example"
ENV_FILE="../.env"

echo "-----------------------------"
echo "✨ Step : Checking environment variables"
echo "-----------------------------"

# Load .env file (without exporting globally)
set -a
source "$ENV_FILE"
set +a

missing_keys=()

while IFS= read -r key; do
  # Remove whitespace and comments
  clean_key=$(echo "$key" | sed 's/#.*//' | xargs)
  [ -z "$clean_key" ] && continue

  if [ -z "${!clean_key+x}" ]; then
    missing_keys+=("$clean_key")
  fi
done < "$ENV_EXAMPLE_FILE"

if [ ${#missing_keys[@]} -ne 0 ]; then
  echo "❌ Missing required environment variables:"
  for key in "${missing_keys[@]}"; do
    echo "   - $key"
  done
  exit 1
else
  echo "✔️ All required environment variables are set."
fi
