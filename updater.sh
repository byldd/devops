#!/bin/bash
source ./utils/loggers.sh
source ./utils/env-checker.sh

POLL_INTERVAL=30
LAST_FRONTEND_DIGEST=""
LAST_BACKEND_DIGEST=""
IS_UPDATED=false

get_digest() {
    local repo=$1
    aws ecr describe-images \
        --repository-name "${repo#*.amazonaws.com/}" \
        --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' \
        --output text
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

while true; do
    log "Polling ECR..."

    CURRENT_FRONTEND_DIGEST=$(get_digest "$ECR_FRONTEND_REPO_URI")
    CURRENT_BACKEND_DIGEST=$(get_digest "$ECR_BACKEND_REPO_URI")

    if [[ "$CURRENT_FRONTEND_DIGEST" != "$LAST_FRONTEND_DIGEST" ]]; then
        log "New frontend image detected. Attempting update..."
        docker compose pull frontend && docker compose up -d --no-deps --force-recreate frontend
        if [[ $? -eq 0 ]]; then
            log "Frontend updated successfully."
            LAST_FRONTEND_DIGEST="$CURRENT_FRONTEND_DIGEST"
            IS_UPDATED=true
        else
            log "Frontend update failed. See above output for details."
        fi
    else
        log "No change in frontend."
    fi

    if [[ "$CURRENT_BACKEND_DIGEST" != "$LAST_BACKEND_DIGEST" ]]; then
        log "New backend image detected. Attempting update..."
        docker compose pull backend && \
            docker compose run --rm --no-deps roles-sync && \
            docker compose up -d --no-deps --force-recreate --remove-orphans backend worker
        if [[ $? -eq 0 ]]; then
            log "Backend and worker updated successfully."
            LAST_BACKEND_DIGEST="$CURRENT_BACKEND_DIGEST"
            IS_UPDATED=true
        else
            log "Backend/worker update failed. See above output for details."
        fi
    else
        log "No change in backend/worker."
    fi

    if [ "$IS_UPDATED" = true ]; then
        # deleting all unused resources
        docker system prune -f
        IS_UPDATED=false
    fi

    sleep "$POLL_INTERVAL"
done
