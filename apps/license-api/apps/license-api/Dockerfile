FROM node:20-alpine

WORKDIR /app

# Copy prebuilt application
COPY dist/apps/license-api ./

# Install only runtime deps
RUN apk add --no-cache wget && \
    npm install --omit=dev --ignore-scripts \
      @nestjs/common@10.4.15 \
      @nestjs/core@10.4.15 \
      @nestjs/platform-express@10.4.15 \
      @nestjs/config@3.4.1 \
      @nestjs/jwt@10.3.0 \
      @nestjs/passport@10.1.0 \
      @nestjs/swagger@8.0.7 \
      @nestjs/throttler@8.0.0 \
      passport@0.7.0 \
      passport-jwt@4.0.2 \
      bcrypt@5.2.1 \
      class-validator@0.14.1 \
      class-transformer@0.5.1 \
      reflect-metadata@0.2.2 \
      rxjs@7.8.1

ENV NODE_ENV=production
ENV LICENSE_API_PORT=3200

EXPOSE 3200
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3200/api/health || exit 1

CMD ["node", "main.js"]
