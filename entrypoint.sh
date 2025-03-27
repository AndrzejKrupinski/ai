#!/bin/bash
set -e

# Print environment details for debugging
echo "Running in $(node -v) environment"
echo "Bun version: $(bun -v)"
echo "Environment: $NODE_ENV"

# Function to check if required API keys are set
check_api_keys() {
  local missing_keys=()

  # Check required keys
  [ -z "$OPENAI_API_KEY" ] && missing_keys+=("OPENAI_API_KEY")
  [ -z "$ANTHROPIC_API_KEY" ] && missing_keys+=("ANTHROPIC_API_KEY")
  [ -z "$LANGFUSE_PUBLIC_KEY" ] && missing_keys+=("LANGFUSE_PUBLIC_KEY")
  [ -z "$LANGFUSE_SECRET_KEY" ] && missing_keys+=("LANGFUSE_SECRET_KEY")

  # Display warning for missing keys
  if [ ${#missing_keys[@]} -gt 0 ]; then
    echo "⚠️ Warning: The following environment variables are not set or empty:"
    for key in "${missing_keys[@]}"; do
      echo "  - $key"
    done
    echo "Some functionality may be limited."

    # Return non-zero if critical keys are missing
    if [[ " ${missing_keys[*]} " =~ "OPENAI_API_KEY" ]]; then
      echo "❌ OPENAI_API_KEY is required to run the application."
      return 1
    fi
  fi

  return 0
}

# Database setup based on database type
setup_database() {
  # Determine database type from DATABASE_URL
  if [[ "$DATABASE_URL" == mysql://* ]]; then
    echo "🛢️ MySQL configuration detected!"
    echo "Waiting for MySQL to be ready..."
    sleep 10
    echo "Proceeding with setup..."
  elif [[ "$DATABASE_URL" == postgres://* ]] || [[ "$DATABASE_URL" == postgresql://* ]]; then
    echo "🐘 PostgreSQL configuration detected!"
    # Wait until PostgreSQL is ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h "${DATABASE_URL#*@}" >/dev/null 2>&1; do
      sleep 1
      echo "⏳ Waiting for PostgreSQL..."
    done
    echo "✅ PostgreSQL is ready!"
  else
    echo "🗃️ SQLite configuration detected, no external database."
  fi

  # Run database migrations and seed regardless of DB type
  echo "📦 Generating database schema..."
  bun generate

  echo "🌱 Running database migrations..."
  bun migrate

  echo "🌱 Seeding database..."
  bun seed

#  echo "🌱 Starting worker..."
#  bun worker:start
}

# Ensure PostgreSQL client tools are available if Postgres is used
if [[ "$DATABASE_URL" == postgres://* ]] || [[ "$DATABASE_URL" == postgresql://* ]]; then
    if ! command -v pg_isready &> /dev/null; then
        echo "🐘 Installing PostgreSQL client tools (for pg_isready)..."
        apt-get update && apt-get install -y postgresql-client
    fi
fi

# Main execution
echo "🚀 Starting Alice AGI setup..."

# Check API keys
if ! check_api_keys; then
  echo "❌ Missing critical environment variables. Exiting."
  exit 1
fi

# Setup the database
setup_database

# Start the application - use exec to replace the shell with the application process
echo "🚀 Starting Alice AGI..."
exec bun run dev
