FROM alpine:latest

ENV LOG_LEVEL=notice \
    HIDDEN_SERVICE_VERSION=3 \
    PRINT_HOSTNAME=true

RUN apk add --no-cache tor ca-certificates gosu \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /etc/tor /var/lib/tor/hidden_service /root/.ssh \
    && chown -R tor:tor /var/lib/tor \
    && chmod 700 /var/lib/tor/hidden_service /root/.ssh

COPY docker-entrypoint.sh /
COPY healthcheck.sh /

RUN sed -i 's/\r//' /docker-entrypoint.sh /healthcheck.sh \
    && chmod +x /docker-entrypoint.sh /healthcheck.sh

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=20s \
    CMD /healthcheck.sh

ENTRYPOINT ["/docker-entrypoint.sh"]