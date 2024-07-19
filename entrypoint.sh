#!/bin/bash

ARGS=()
MODE="bash"
SCALE=30
WORKERS=4
SERVER_MEMORY=4096
INTERVAL=1
GET_RATIO=0.8
CONNECTION=200
RPS=10000
NEGATIVE_EXPONENTIAL=false

while (( ${#@} )); do
  case ${1} in
    --m=*)       MODE=${1#*=} ;;
    --S=*)       SCALE=${1#*=} ;;
    --w=*)       WORKERS=${1#*=} ;;
    --D=*)       SERVER_MEMORY=${1#*=} ;;
    --T=*)       INTERVAL=${1#*=} ;;
    --g=*)       GET_RATIO=${1#*=} ;;
    --c=*)       CONNECTION=${1#*=} ;;
    --r=*)       RPS=${1#*=} ;;
    --ne)        NEGATIVE_EXPONENTIAL=true ;;       
    *)           ARGS+=(${1}) ;;
  esac

  shift
done

set -- ${ARGS[@]}

if [ "$MODE" = 'S&W' ]; then
        echo "scale and warmup"
        memcached_client/loader \
                -a twitter_dataset/twitter_dataset_unscaled \
                -o twitter_dataset/twitter_dataset_${SCALE}x \
                -s memcached_client/docker_servers/docker_servers.txt \
                -w ${WORKERS} -S ${SCALE} -D ${SERVER_MEMORY} -j -T ${INTERVAL}
elif [ "$MODE" = 'W' ]; then
        echo "warmup"
        memcached_client/loader \
                -a twitter_dataset/twitter_dataset_${SCALE}x \
                -s memcached_client/docker_servers/docker_servers.txt \
                -w ${WORKERS} -S 1 -D ${SERVER_MEMORY} -j -T ${INTERVAL}
elif [ "$MODE" = 'TH' ]; then
        echo "max throughput"
        memcached_client/loader \
                -a twitter_dataset/twitter_dataset_${SCALE}x \
                -s memcached_client/docker_servers/docker_servers.txt \
                -g ${GET_RATIO} -w ${WORKERS} -c ${CONNECTION} -T ${INTERVAL}
elif [ "$MODE" = 'RPS' ]; then
        echo "RPS"
        if [ "$NEGATIVE_EXPONENTIAL" = true ]; then
                ADDITIONAL_OPTION="-e"
        fi
        memcached_client/loader \
                -a twitter_dataset/twitter_dataset_${SCALE}x \
                -s memcached_client/docker_servers/docker_servers.txt \
                -g ${GET_RATIO} -w ${WORKERS} -c ${CONNECTION} -T ${INTERVAL} $ADDITIONAL_OPTION -r ${RPS}
elif [ "$MODE" = "bash" ]; then
        # bash
        exec /bin/bash
fi

