# Flutter Web - Tierbesitzer App
# Build-Kontext: Repo-Root (enthält shared/ und web_owner/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Shared-Paket + Manifest zuerst kopieren, damit pub get die Abhängigkeiten findet
COPY shared/ /app/shared/
COPY web_owner/pubspec.yaml web_owner/pubspec.lock* /app/web_owner/
WORKDIR /app/web_owner
RUN flutter pub get

# Restlichen Quellcode kopieren
COPY web_owner/ /app/web_owner/

RUN flutter build web --release --web-renderer html

# Production Image mit Nginx
FROM nginx:alpine

COPY web_owner/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_owner/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
