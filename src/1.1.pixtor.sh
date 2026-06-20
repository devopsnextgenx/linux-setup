#!/bin/sh
# Setup /home/shared/pixtor for docker-compose volume mounts.
# Intended to be appended to (or sourced from) the main /home/shared bootstrap script.
#
# Rootless Podman/Docker maps container UID 999 to SUBUID_BASE+999 on the host.
# Default SUBUID_BASE is 100000 (see /etc/subuid for $USER).

set -eu

PIXTOR_BASE="/home/shared/pixtor"
REPO_ROOT_DEFAULT="/home/kira/git/devopsnextgenx/pixtor"
printf "Pixtor repo root [%s]: " "$REPO_ROOT_DEFAULT"
read -r REPO_ROOT_INPUT || REPO_ROOT_INPUT=""
REPO_ROOT="${REPO_ROOT_INPUT:-$REPO_ROOT_DEFAULT}"
echo "  using repo root: ${REPO_ROOT}"

SUBUID_BASE="$(awk -F: -v user="${USER:?USER must be set}" '$1 == user { print $2; exit }' /etc/subuid)"
SUBGID_BASE="$(awk -F: -v user="${USER:?USER must be set}" '$1 == user { print $2; exit }' /etc/subuid)"
SUBUID_BASE="${SUBUID_BASE:-100000}"
SUBGID_BASE="${SUBGID_BASE:-100000}"

CONTAINER_DB_UID=$((SUBUID_BASE + 999))
CONTAINER_REDIS_GID=$((SUBGID_BASE + 1000))

echo "Setting up pixtor shared directory at ${PIXTOR_BASE}..."
echo "  container DB UID/GID on host: ${CONTAINER_DB_UID}"
echo "  container redis GID on host:  ${CONTAINER_REDIS_GID}"

sudo mkdir -p \
  "${PIXTOR_BASE}/conf" \
  "${PIXTOR_BASE}/scripts" \
  "${PIXTOR_BASE}/ui" \
  "${PIXTOR_BASE}/docker-data/redis" \
  "${PIXTOR_BASE}/docker-data/mongodb" \
  "${PIXTOR_BASE}/docker-data/mysql" \
  "${PIXTOR_BASE}/docker-data/qdrant-primary" \
  "${PIXTOR_BASE}/docker-data/qdrant-secondary"

# conf, scripts, ui — user-managed, group-writable via shared
sudo chown -R "${USER}:shared" \
  "${PIXTOR_BASE}/conf" \
  "${PIXTOR_BASE}/scripts" \
  "${PIXTOR_BASE}/ui"
sudo chmod -R g+rwx \
  "${PIXTOR_BASE}/conf" \
  "${PIXTOR_BASE}/scripts" \
  "${PIXTOR_BASE}/ui"
sudo find "${PIXTOR_BASE}/conf" "${PIXTOR_BASE}/scripts" "${PIXTOR_BASE}/ui" \
  -type d -exec chmod g+s {} +

# Seed config from repo when directories are empty (first install)
if [ ! -f "${PIXTOR_BASE}/conf/pixtor.yml" ] && [ -f "${REPO_ROOT}/conf/pixtor.yml" ]; then
  echo "  seeding conf/ from ${REPO_ROOT}/conf/"
  sudo cp -a "${REPO_ROOT}/conf/." "${PIXTOR_BASE}/conf/"
  sudo chown -R "${USER}:shared" "${PIXTOR_BASE}/conf"
fi
if [ ! -f "${PIXTOR_BASE}/scripts/mysql-init.sql" ] && [ -f "${REPO_ROOT}/scripts/mysql-init.sql" ]; then
  echo "  seeding scripts/ from ${REPO_ROOT}/scripts/"
  sudo cp -a "${REPO_ROOT}/scripts/." "${PIXTOR_BASE}/scripts/"
  sudo chown -R "${USER}:shared" "${PIXTOR_BASE}/scripts"
fi
if [ ! -f "${PIXTOR_BASE}/ui/index.html" ] && [ -f "${REPO_ROOT}/ui/index.html" ]; then
  echo "  seeding ui/ from ${REPO_ROOT}/ui/"
  sudo cp -a "${REPO_ROOT}/ui/." "${PIXTOR_BASE}/ui/"
  sudo chown -R "${USER}:shared" "${PIXTOR_BASE}/ui"
fi

# docker-data parent — traversable, owned by user for administration
sudo chown "${USER}:shared" "${PIXTOR_BASE}" "${PIXTOR_BASE}/docker-data"
sudo chmod 755 "${PIXTOR_BASE}" "${PIXTOR_BASE}/docker-data"

# mysql, mongodb, redis — rootless mapped container service users
sudo chown -R "${CONTAINER_DB_UID}:${CONTAINER_DB_UID}" \
  "${PIXTOR_BASE}/docker-data/mysql" \
  "${PIXTOR_BASE}/docker-data/mongodb"
sudo chown -R "${CONTAINER_DB_UID}:${CONTAINER_REDIS_GID}" \
  "${PIXTOR_BASE}/docker-data/redis"
sudo chmod 755 \
  "${PIXTOR_BASE}/docker-data/mysql" \
  "${PIXTOR_BASE}/docker-data/mongodb" \
  "${PIXTOR_BASE}/docker-data/redis"

# qdrant — container runs as root; user:shared with group write is sufficient
sudo chown -R "${USER}:shared" \
  "${PIXTOR_BASE}/docker-data/qdrant-primary" \
  "${PIXTOR_BASE}/docker-data/qdrant-secondary"
sudo chmod -R g+rwx \
  "${PIXTOR_BASE}/docker-data/qdrant-primary" \
  "${PIXTOR_BASE}/docker-data/qdrant-secondary"
sudo find \
  "${PIXTOR_BASE}/docker-data/qdrant-primary" \
  "${PIXTOR_BASE}/docker-data/qdrant-secondary" \
  -type d -exec chmod g+s {} +

echo "Pixtor shared directory ready."
