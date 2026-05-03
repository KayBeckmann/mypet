# Flutter Web - Tierbesitzer App
# Build-Kontext: Repo-Root (enthält shared/ und web_owner/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

# API-URL konfigurierbar über docker-compose build-args / .env
ARG API_BASE_URL=http://localhost:8080

WORKDIR /app

# Shared-Paket + Manifest zuerst kopieren, damit pub get die Abhängigkeiten findet
COPY shared/ /app/shared/
COPY web_owner/pubspec.yaml web_owner/pubspec.lock* /app/web_owner/
WORKDIR /app/web_owner
RUN flutter pub get

# Restlichen Quellcode kopieren
COPY web_owner/ /app/web_owner/

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/

# Production Image mit Nginx
FROM nginx:alpine

COPY web_owner/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_owner/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
