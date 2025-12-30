#!/bin/bash
set -e

NGINX_CONTAINER="nginx_lb"
UPSTREAM_CONF="./nginx/conf.d/upstream.conf"

CURRENT_COLOR=$(grep "default" $UPSTREAM_CONF | awk '{print $2}' | cut -d'_' -f1)
echo "Rollback initiated. Current active: $CURRENT_COLOR"

if [ "$CURRENT_COLOR" == "blue" ]; then
    TARGET_COLOR="green"
else
    TARGET_COLOR="blue"
fi

echo "Rolling back to: $TARGET_COLOR"

# Ensure target container is running
if [ "$(docker inspect -f '{{.State.Running}}' ${TARGET_COLOR}_app 2>/dev/null)" != "true" ]; then
    echo "Warning: $TARGET_COLOR container is not running. Starting it..."
    docker-compose up -d $TARGET_COLOR
    # Quick health check (optional but recommended)
    sleep 5
fi

# Switch traffic
sed -i "s/default ${CURRENT_COLOR}_upstream;/default ${TARGET_COLOR}_upstream;/g" $UPSTREAM_CONF

# Reload NGINX
docker-compose exec -T nginx nginx -s reload

echo "Rollback complete. Active: $TARGET_COLOR"
