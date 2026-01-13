#!/bin/bash

# Licensing Service - Deploy to Unraid
# Syncs code and restarts containers

set -e

UNRAID_HOST="unraid"
UNRAID_USER="root"
DEPLOY_PATH="/mnt/user/appdata/licensing-service"
UNRAID_SSH="${UNRAID_USER}@${UNRAID_HOST}"

echo "🚀 Deploying Licensing Service to Unraid..."
echo ""

# Step 1: Sync application code
echo "📦 Step 1/6: Syncing application code..."
rsync -az --delete \
    --exclude 'node_modules' \
    --exclude 'dist' \
    --exclude '.env' \
    --exclude '.env.local' \
    --exclude '*.db' \
    --exclude '*.db-journal' \
    ./apps/ $UNRAID_SSH:$DEPLOY_PATH/apps/

echo "✅ Code synced"
echo ""

# Step 2: Sync Prisma schema and migrations
echo "🗄️  Step 2/6: Syncing Prisma schema..."
rsync -az --delete ./prisma/ $UNRAID_SSH:$DEPLOY_PATH/prisma/

echo "✅ Prisma synced"
echo ""

# Step 3: Sync package files
echo "📋 Step 3/6: Syncing package configuration..."
rsync -az \
    ./package.json \
    ./package-lock.json \
    ./nx.json \
    ./tsconfig.base.json \
    $UNRAID_SSH:$DEPLOY_PATH/

echo "✅ Package files synced"
echo ""

# Step 4: Sync docker configs
echo "🐳 Step 4/6: Syncing Docker configurations..."
rsync -az ./docker/ $UNRAID_SSH:$DEPLOY_PATH/docker/

echo "✅ Docker configs synced"
echo ""

# Step 5: Setup Docker environment
echo "🐳 Step 5/6: Setting up Docker environment..."
ssh $UNRAID_SSH "mkdir -p $DEPLOY_PATH"

cat << 'EOF' | ssh $UNRAID_SSH "cat > $DEPLOY_PATH/docker-compose.yml"
version: '3.8'

services:
  license-api:
    image: node:20-alpine
    container_name: licensing-service-api
    working_dir: /app
    volumes:
      - ./:/app
    ports:
      - "3200:3200"
    environment:
      - NODE_ENV=production
      - PORT=3200
    env_file:
      - .env
    command: >
      sh -c "
        if [ ! -d node_modules ]; then
          echo '📦 Installing dependencies...' &&
          npm ci --legacy-peer-deps
        fi &&
        echo '🔨 Building application...' &&
        npx nx build license-api --skip-nx-cache &&
        echo '🚀 Starting server with auto-reload...' &&
        npx nodemon --watch apps/license-api --watch libs --ext ts,js,json --exec 'npx nx build license-api --skip-nx-cache && node dist/apps/license-api/main.js'
      "
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3200/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  license-fe:
    image: node:20-alpine
    container_name: licensing-service-fe
    working_dir: /app
    volumes:
      - ./:/app
      - fe-dist:/app/dist/apps/license-fe
    ports:
      - "4210:4210"
    environment:
      - NODE_ENV=production
    command: >
      sh -c "
        if [ ! -d node_modules ]; then
          echo '📦 Installing dependencies...' &&
          npm ci --legacy-peer-deps
        fi &&
        echo '🔨 Building admin dashboard...' &&
        npx nx build license-fe --configuration=production &&
        echo '🚀 Serving admin dashboard...' &&
        npx http-server dist/apps/license-fe/browser -p 4210
      "
    restart: unless-stopped
    depends_on:
      - license-api

volumes:
  fe-dist:
EOF

echo "✅ Docker compose configured"
echo ""

# Step 6: Start/restart container
echo "♻️  Step 6/6: Starting license-api container..."
ssh $UNRAID_SSH "cd $DEPLOY_PATH && docker-compose up -d"

echo "✅ Container started"
echo ""

echo "⏳ Waiting for API to be ready..."
sleep 10

# Health check
if ssh $UNRAID_SSH "curl -f http://localhost:3200/api/health" > /dev/null 2>&1; then
    echo "✅ License API is healthy"
else
    echo "⚠️  Health check failed (may still be starting)"
    echo ""
    echo "Check logs:"
    echo "  ssh $UNRAID_SSH 'docker logs -f licensing-service-api'"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 License API:    http://192.168.1.100:3200/api"
echo "📍 Admin Dashboard: http://192.168.1.100:4210"
echo "📍 Public API URL:  https://api.bitbonsai.app (or your configured domain)"
echo ""
echo "💡 Watch logs:"
echo "   ssh $UNRAID_SSH 'docker logs -f licensing-service-api'"
echo "   ssh $UNRAID_SSH 'docker logs -f licensing-service-fe'"
