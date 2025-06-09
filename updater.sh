#!/bin/bash

source ./utils/env-checker.sh

POLL_INTERVAL=30
LAST_FRONTEND_DIGEST=""
LAST_BACKEND_DIGEST=""

get_digest() {
    local repo=$1
    aws ecr describe-images \
        --repository-name "${repo##*/}" \
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
            # Remove all unused images
            docker image prune -a
            LAST_FRONTEND_DIGEST="$CURRENT_FRONTEND_DIGEST"
        else
            log "Frontend update failed. See above output for details."
        fi
    else
        log "No change in frontend."
    fi

    if [[ "$CURRENT_BACKEND_DIGEST" != "$LAST_BACKEND_DIGEST" ]]; then
        log "New backend image detected. Attempting update..."
        docker compose pull backend && docker compose up -d --no-deps --force-recreate backend cron
        if [[ $? -eq 0 ]]; then
            log "Backend and cron updated successfully."
            # Remove all unused images
            LAST_BACKEND_DIGEST="$CURRENT_BACKEND_DIGEST"
        else
            log "Backend/cron update failed. See above output for details."
        fi
    else
        log "No change in backend/cron."
    fi

    sleep "$POLL_INTERVAL"
done
