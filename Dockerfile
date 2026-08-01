# syntax=docker/dockerfile:1

# ---- Build stage: compile the Angular production bundle ----
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---- Runtime stage: serve the static bundle with nginx on port 4200 ----
FROM nginx:1.27-alpine AS runtime

# Static SPA output produced by @angular/build:application
COPY --from=build /app/dist/angular-prod/browser /usr/share/nginx/html

# nginx vhost that listens on 4200 with SPA history fallback
COPY deploy/nginx-container.conf /etc/nginx/conf.d/default.conf

EXPOSE 4200

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:4200/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
