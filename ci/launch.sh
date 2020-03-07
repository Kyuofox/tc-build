#!/usr/bin/env bash

set -ufo pipefail
cd "$(dirname "$0")"

tf_vars=(-var packet_token="${1:-$PACKET_TOKEN}" -var github_token="${2:-$GH_TOKEN}" -var packet_ssh_key="${3:-$PACKET_SSH_KEY}" -var github_run_id="${GITHUB_RUN_ID:-}" -var telegram_chat_id="${4:-$TG_CHAT_ID}" -var telegram_token="${5:-$TG_TOKEN}" -var git_author_name="${6:-$GIT_AUTHOR_NAME}" -var git_author_email="${7:-$GIT_AUTHOR_EMAIL}")

terraform init
terraform apply -auto-approve "${tf_vars[@]}"
terraform destroy -auto-approve "${tf_vars[@]}"
