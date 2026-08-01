#!/usr/bin/env bash
#
# Build, push, and deploy the angular-prod app to a remote server.
#
# The app is served by an nginx container listening on port 4200. On the
# server, a host nginx vhost reverse-proxies https://cases.hsc.org.zw -> :4200.
#
# Required environment variables:
#   DEPLOY_HOST        Server IP or hostname (e.g. 203.0.113.10)
#   DEPLOY_USER        SSH user (e.g. ubuntu / root)
#
# Optional environment variables (with defaults):
#   IMAGE              Docker image name        (default: fyntan263/angular-prod)
#   TAG                Image tag                (default: latest)
#   CONTAINER_NAME     Running container name   (default: angular-prod)
#   HOST_PORT          Port published on server (default: 4200)
#   SSH_KEY            Path to private key      (default: ssh-agent / ~/.ssh/id_*)
#   DOMAIN             Public domain            (default: cases.hsc.org.zw)
#
# Registry auth: run `docker login -u fyntan263` (or set DOCKER_PASSWORD and this
# script will log in non-interactively) before running, so `docker push` works.
#
set -euo pipefail

IMAGE="${IMAGE:-fyntan263/angular-prod}"
TAG="${TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-angular-prod}"
HOST_PORT="${HOST_PORT:-4200}"
DOMAIN="${DOMAIN:-cases.hsc.org.zw}"
FULL_IMAGE="${IMAGE}:${TAG}"

: "${DEPLOY_HOST:?Set DEPLOY_HOST to the server IP/hostname}"
: "${DEPLOY_USER:?Set DEPLOY_USER to the SSH user}"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_KEY:-}" ]]; then
  SSH_OPTS+=(-i "${SSH_KEY}")
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> [1/5] Optional registry login"
if [[ -n "${DOCKER_PASSWORD:-}" ]]; then
  echo "${DOCKER_PASSWORD}" | docker login -u "${IMAGE%%/*}" --password-stdin
fi

echo "==> [2/5] Building ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" "${REPO_ROOT}"

echo "==> [3/5] Pushing ${FULL_IMAGE} to registry"
docker push "${FULL_IMAGE}"

echo "==> [4/5] Deploying container on ${DEPLOY_USER}@${DEPLOY_HOST}"
ssh "${SSH_OPTS[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" bash -s <<REMOTE
set -euo pipefail
echo "  - pulling ${FULL_IMAGE}"
docker pull "${FULL_IMAGE}"
echo "  - restarting container ${CONTAINER_NAME}"
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
docker run -d --name "${CONTAINER_NAME}" --restart unless-stopped \
  -p 127.0.0.1:${HOST_PORT}:4200 "${FULL_IMAGE}"
echo "  - container status:"
docker ps --filter "name=${CONTAINER_NAME}"
REMOTE

echo "==> [5/5] Configuring host nginx for ${DOMAIN}"
scp "${SSH_OPTS[@]}" "${SCRIPT_DIR}/nginx-cases.hsc.org.zw.conf" \
  "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/${DOMAIN}.conf"
ssh "${SSH_OPTS[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" bash -s <<REMOTE
set -euo pipefail
sudo cp "/tmp/${DOMAIN}.conf" "/etc/nginx/sites-available/${DOMAIN}"
sudo ln -sf "/etc/nginx/sites-available/${DOMAIN}" "/etc/nginx/sites-enabled/${DOMAIN}"
sudo nginx -t
sudo systemctl reload nginx
echo "  - nginx reloaded"
REMOTE

echo "==> Done. Verify: curl -I http://${DOMAIN}/"
