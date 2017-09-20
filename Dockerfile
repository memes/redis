FROM alpine:3.6
MAINTAINER Matthew Emes "matthew.emes@neudesic.com"
RUN apk add --no-cache redis
WORKDIR /var/lib/redis
COPY launch_redis.sh .
COPY server.conf .
COPY sentinel.conf .
RUN chmod 0755 launch_redis.sh && \
    chmod 0640 server.conf sentinel.conf && \
    chown redis:redis server.conf sentinel.conf
USER redis
ENTRYPOINT [ "/var/lib/redis/launch_redis.sh" ]
