FROM node:16-alpine AS builder

WORKDIR /application

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build


FROM nginx:alpine

# Update Alpine package index and upgrade packages
RUN apk update && \
    apk upgrade

# Explicitly install the fixed util-linux package
RUN apk add --no-cache \
    util-linux=2.42.3-r0

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /application/build /usr/share/nginx/html

RUN sed -i 's/listen       80;/listen       3000;/' /etc/nginx/conf.d/default.conf

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
