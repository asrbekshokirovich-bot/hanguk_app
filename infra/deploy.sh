#!/usr/bin/env bash
# deploy.sh — push local source to the VPS, install/refresh the venv,
# drop systemd units, restart workers.
#
# Usage:
#   infra/deploy.sh <vps-ipv4>
#
# Idempotent. Does NOT touch /etc/uni_db/env — that file is hand-managed
# (or set up via the Gemini deploy prompt in Phase D).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <vps-ipv4>" >&2
  exit 1
fi

VPS="$1"
SSH_TARGET="root@${VPS}"

# Sanity: confirm we can reach the VPS first
echo "[deploy] checking ssh..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  "$SSH_TARGET" 'echo ok' >/dev/null

# 1. Push the Python service
echo "[deploy] rsync services/uni_db/ -> /opt/uni_db/services/uni_db/"
rsync -az --delete \
  --exclude='.git' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.venv' \
  --exclude='.pytest_cache' \
  --exclude='.staging-secrets.txt' \
  --exclude='.prod-db-url.txt' \
  --exclude='.env' \
  services/uni_db/ \
  "${SSH_TARGET}:/opt/uni_db/services/uni_db/"

# 2. Push systemd unit files
echo "[deploy] copy systemd units"
rsync -az infra/systemd/ "${SSH_TARGET}:/etc/systemd/system/"

# 3. Install/refresh the venv on the VPS
echo "[deploy] venv install on VPS"
ssh "$SSH_TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail
cd /opt/uni_db/services/uni_db
chown -R uni-db:uni-db /opt/uni_db
if [[ ! -d .venv ]]; then
  sudo -u uni-db python3.12 -m venv .venv
fi
sudo -u uni-db .venv/bin/pip install --quiet --upgrade pip
sudo -u uni-db .venv/bin/pip install --quiet -e ".[heavy]"
REMOTE

# 4. Reload systemd, enable + (re)start units
echo "[deploy] systemd reload + restart"
ssh "$SSH_TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail
systemctl daemon-reload
systemctl enable --now \
  uni-db-discovery-poll.timer \
  uni-db-extract.service \
  uni-db-translate.service \
  uni-db-ocr.service
systemctl restart \
  uni-db-extract.service \
  uni-db-translate.service \
  uni-db-ocr.service
REMOTE

# 5. Smoke check — show the last 20 lines from each unit
echo "[deploy] post-restart status"
ssh "$SSH_TARGET" 'bash -s' <<'REMOTE'
echo "--- uni-db-extract ---"
journalctl -u uni-db-extract -n 20 --no-pager
echo "--- uni-db-translate ---"
journalctl -u uni-db-translate -n 20 --no-pager
echo "--- uni-db-ocr ---"
journalctl -u uni-db-ocr -n 20 --no-pager
REMOTE

echo "[deploy] done."
