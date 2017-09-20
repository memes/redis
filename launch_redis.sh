#!/bin/sh
#
# Launches various redis components depending on environment
#
# Note: sh in this case is from busybox so watch out!

# Provide some sane defaults
[[ -z "${REDIS_BOOTSTRAP_SERVICE_HOST}" ]] && REDIS_BOOTSTRAP_SERVICE_HOST=bootstrap-service
[[ -z "${REDIS_BOOTSTRAP_SERVICE_PORT}" ]] && REDIS_BOOTSTRAP_SERVICE_PORT=6379
[[ -z "${REDIS_SENTINEL_SERVICE_HOST}" ]] && REDIS_SENTINEL_SERVICE_HOST=sentinel-service
[[ -z "${REDIS_SENTINEL_SERVICE_PORT}" ]] && REDIS_SENTINEL_SERVICE_PORT=26379
[[ -z "${REDIS_SERVICE_HOST}" ]] && REDIS_SERVICE_HOST=redis-service
[[ -z "${REDIS_SERVICE_PORT}" ]] && REDIS_SERVICE_PORT=6379


function error() {
    echo "$0: $*" >&2
    exit 1
}

function info() {
    echo "$0: $*" >&2
}

if [[ -n "${LAUNCH_AS_BOOTSTRAP}" ]]; then
   info "Launching a bootstrap server"
   /usr/bin/redis-server /var/lib/redis/server.conf \
       --port ${REDIS_BOOTSTRAP_SERVICE_PORT}
    exit $?
fi

# Figure out what the current master is from a sentinel, fallback to advertised
# bootstrap
while [[ -z "${MASTER_ADDRESS}" ]]; do
    info "Trying to connect to sentinel service ingress on ${REDIS_SENTINEL_SERVICE_HOST}:${REDIS_SENTINEL_SERVICE_PORT}"
    address=$(timeout -t 10 redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name master 2>/dev/null | tr -d '"')
    MASTER_ADDRESS=$(echo $address | awk -F, '{print $1}')
    MASTER_PORT=$(echo $address | awk -F, '{print $2}')
    if [[ -n "${MASTER_ADDRESS}" ]] && [[ -n "${MASTER_PORT}" ]]; then
	    info "Using master address from a running sentinel: ${MASTER_ADDRESS}:${MASTER_PORT}"
	    break
    fi
    info "Trying to connect to a known running bootstrap at ${REDIS_BOOTSTRAP_SERVICE_HOST}:${REDIS_BOOTSTRAP_SERVICE_PORT}"
    timeout -t 10 redis-cli -h ${REDIS_BOOTSTRAP_SERVICE_HOST} \
	        -p ${REDIS_BOOTSTRAP_SERVICE_PORT} \
	        INFO >/dev/null 2>/dev/null && \
	    MASTER_ADDRESS=${REDIS_BOOTSTRAP_SERVICE_HOST} && \
	    MASTER_PORT=${REDIS_BOOTSTRAP_SERVICE_PORT}
    if [[ -n "${MASTER_ADDRESS}" ]]; then
	    info "Using currently running bootstrap service: ${MASTER_ADDRESS}:${MASTER_PORT}"
	    break
    fi
    info "Sleeping for a bit..."
    sleep 10
done

if [[ -n "${LAUNCH_AS_SENTINEL}" ]]; then
    info "Launching a sentinel..."
    [[ -z "${MASTER_ADDRESS}" ]] && error "Can't determine master address"
    sed -i -e "s/##masteraddress##/${MASTER_ADDRESS} ${MASTER_PORT}/" /var/lib/redis/sentinel.conf
    /usr/bin/redis-sentinel /var/lib/redis/sentinel.conf \
        --port ${REDIS_SENTINEL_SERVICE_PORT}
    exit $?
fi

# Must be a slave
info "Launching as a slave to ${MASTER_ADDRESS} ${MASTER_PORT}"
[[ -z "${MASTER_ADDRESS}" ]] && error "Can't determine master address"
/usr/bin/redis-server /var/lib/redis/server.conf \
    --slaveof ${MASTER_ADDRESS} ${MASTER_PORT}
