# Flutter Web - Tierbesitzer App
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Dependencies installieren
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Source Code kopieren
COPY . .

# Flutter Web Build
RUN flutter build web --release

# Production Image mit Nginx
FROM nginx:alpine

# Nginx Konfiguration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Build Output kopieren
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
