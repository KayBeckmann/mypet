# Flutter Web - Tierarzt App
# Build-Kontext: Repo-Root (enthält shared/ und web_vet/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Shared-Paket + Manifest zuerst kopieren, damit pub get die Abhängigkeiten findet
COPY shared/ /app/shared/
COPY web_vet/pubspec.yaml web_vet/pubspec.lock* /app/web_vet/
WORKDIR /app/web_vet
RUN flutter pub get

# Restlichen Quellcode kopieren
COPY web_vet/ /app/web_vet/

RUN flutter build web --release

# Production Image mit Nginx
FROM nginx:alpine

COPY web_vet/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_vet/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
