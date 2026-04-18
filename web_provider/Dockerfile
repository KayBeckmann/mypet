# Flutter Web - Dienstleister App
# Build-Kontext: Repo-Root (enthält shared/ und web_provider/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY shared/ /app/shared/
COPY web_provider/pubspec.yaml web_provider/pubspec.lock* /app/web_provider/
WORKDIR /app/web_provider
RUN flutter pub get

COPY web_provider/ /app/web_provider/

RUN flutter build web --release

# Production Image mit Nginx
FROM nginx:alpine

COPY web_provider/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_provider/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
