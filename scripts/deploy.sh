#!/bin/bash
set -e

# Configuration
NGINX_CONTAINER="nginx_lb"
UPSTREAM_CONF="./nginx/conf.d/upstream.conf"

# 1. Determine current active color
# We grep the upstream.conf to see which one is default
CURRENT_COLOR=$(grep "default" $UPSTREAM_CONF | awk '{print $2}' | cut -d'_' -f1)
echo "Current active color: $CURRENT_COLOR"

if [ "$CURRENT_COLOR" == "blue" ]; then
    NEW_COLOR="green"
elif [ "$CURRENT_COLOR" == "green" ]; then
    NEW_COLOR="blue"
else
    echo "Error: Could not determine current color."
    exit 1
fi

echo "Deploying to: $NEW_COLOR"

# 2. Start the new container
echo "Starting $NEW_COLOR container..."
docker-compose up -d $NEW_COLOR

# 3. Wait for health check
echo "Waiting for $NEW_COLOR to be healthy..."
# Retry loop
for i in {1..30}; do
    # specific container IP or checking localhost if port mapped? 
    # Since we are outside, we might rely on docker inspect or internal network.
    # But wait, docker-compose exposes port 5000 for both? That would conflict if both map to 5000:5000 on host.
    # START_CHECK: In docker-compose.yml, I didn't verify ports.
    # Ah, I see:
    # blue: expose 5000
    # green: expose 5000
    # They are NOT port mapped to host 5000. They are only on internal network. 
    # So I cannot curl localhost:5000 to check them individually unless I exec into nginx or use another way.
    
    # Let's use docker exec to curl from inside nginx container (it can reach blue/green by name)
    HEALTH_STATUS=$(docker exec $NGINX_CONTAINER curl -s -o /dev/null -w "%{http_code}" http://$NEW_COLOR:5000/health || true)
    
    if [ "$HEALTH_STATUS" == "200" ]; then
        echo "$NEW_COLOR is healthy!"
        break
    fi
    echo "Waiting for health check... ($i/30)"
    sleep 2
done

if [ "$HEALTH_STATUS" != "200" ]; then
    echo "Health check failed for $NEW_COLOR. Aborting deployment."
    echo "Stopping $NEW_COLOR container..."
    docker-compose stop $NEW_COLOR
    exit 1
fi

# 4. Switch traffic
echo "Switching traffic to $NEW_COLOR..."
# We replace the map default
sed -i "s/default ${CURRENT_COLOR}_upstream;/default ${NEW_COLOR}_upstream;/g" $UPSTREAM_CONF

# 5. Reload NGINX
echo "Reloading NGINX..."
docker-compose exec -T nginx nginx -s reload

echo "Deployment complete! Active: $NEW_COLOR"

# 6. Optional: Stop old container?
# In Blue-Green, we often keep it running for a bit, or stop it to save resources.
# For "Instant Rollback" we might keep it running.
echo "Previous version ($CURRENT_COLOR) is still running. Run 'docker-compose stop $CURRENT_COLOR' to save resources if satisfied."
