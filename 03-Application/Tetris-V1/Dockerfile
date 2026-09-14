# =========================
# Stage 1: Build React app
# =========================
FROM node:16-alpine AS builder

WORKDIR /application

# Install dependencies first for better Docker caching
COPY package.json package-lock.json ./
RUN npm ci

# Copy application source
COPY . .

# Build React application
RUN npm run build


# =========================
# Stage 2: Nginx runtime
# =========================
FROM nginx:alpine

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy React production build
COPY --from=builder /application/build /usr/share/nginx/html

# Change Nginx from port 80 to 3000
RUN sed -i 's/listen       80;/listen       3000;/' /etc/nginx/conf.d/default.conf

EXPOSE 3000

# Container health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/ || exit 1

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
