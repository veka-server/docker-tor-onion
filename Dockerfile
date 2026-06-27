FROM alpine:latest

ENV TOR_DATA_DIR=/var/lib/tor \
    HIDDEN_SERVICE_DIR=/var/lib/tor/hidden_service \
    LOG_LEVEL=notice \
    HIDDEN_SERVICE_VERSION=3 \
    PRINT_HOSTNAME=true

# Packages nécessaires
RUN apk add --no-cache tor ca-certificates gosu \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /etc/tor /var/lib/tor /root/.ssh \
    && chmod 700 /root/.ssh

COPY docker-entrypoint.sh /
COPY healthcheck.sh /

RUN chmod +x /usr/local/bin/*

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=20s \
    CMD /healthcheck.sh

ENTRYPOINT ["/docker-entrypoint.sh"]