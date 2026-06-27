#!/bin/bash

set -Eeuo pipefail

TORRC=/etc/tor/torrc

mkdir -p "$TOR_DATA_DIR"
mkdir -p "$HIDDEN_SERVICE_DIR"

chown -R alpine-tor:alpine-tor "$TOR_DATA_DIR"

cat > "$TORRC" <<EOF
Log ${LOG_LEVEL} stdout

RunAsDaemon 0

DataDirectory ${TOR_DATA_DIR}

HiddenServiceDir ${HIDDEN_SERVICE_DIR}

HiddenServiceVersion ${HIDDEN_SERVICE_VERSION}
EOF

########################################
# Single service
########################################

if [[ -n "${TARGET_HOST:-}" ]]; then

    TARGET_PORT="${TARGET_PORT:-80}"
    ONION_PORT="${ONION_PORT:-80}"

    echo "HiddenServicePort ${ONION_PORT} ${TARGET_HOST}:${TARGET_PORT}" >> "$TORRC"

fi

########################################
# Multiple services
########################################

if [[ -n "${HIDDEN_SERVICE_PORTS:-}" ]]; then

while read LINE
do

    [[ -z "$LINE" ]] && continue

    ONION=$(echo "$LINE" | cut -d: -f1)
    HOST=$(echo "$LINE" | cut -d: -f2)
    PORT=$(echo "$LINE" | cut -d: -f3)

    echo "HiddenServicePort ${ONION} ${HOST}:${PORT}" >> "$TORRC"

done <<< "$HIDDEN_SERVICE_PORTS"

fi

########################################
# Extra Tor configuration
########################################

if [[ -n "${TOR_EXTRA_CONFIG:-}" ]]; then
    echo "$TOR_EXTRA_CONFIG" >> "$TORRC"
fi

echo "========== torrc =========="
cat "$TORRC"
echo "==========================="

exec gosu alpine-tor tor -f "$TORRC"