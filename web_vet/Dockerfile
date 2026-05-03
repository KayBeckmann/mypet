# Flutter Web - Tierarzt App
# Build-Kontext: Repo-Root (enthält shared/ und web_vet/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG API_BASE_URL=http://localhost:8080

WORKDIR /app

COPY shared/ /app/shared/
COPY web_vet/pubspec.yaml web_vet/pubspec.lock* /app/web_vet/
WORKDIR /app/web_vet
RUN flutter pub get

COPY web_vet/ /app/web_vet/

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/

# Production Image mit Nginx
FROM nginx:alpine

COPY web_vet/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_vet/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
