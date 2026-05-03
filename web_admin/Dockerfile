# Flutter Web - Admin Dashboard
# Build-Kontext: Repo-Root (enthält shared/ und web_admin/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG API_BASE_URL=http://localhost:8080

WORKDIR /app

COPY shared/ /app/shared/
COPY web_admin/pubspec.yaml web_admin/pubspec.lock* /app/web_admin/
WORKDIR /app/web_admin
RUN flutter pub get

COPY web_admin/ /app/web_admin/

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/

FROM nginx:alpine

COPY web_admin/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/web_admin/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
