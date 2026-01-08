# Backend Dockerfile - Dart
FROM dart:stable AS build

WORKDIR /app

# Dependencies installieren
COPY pubspec.yaml pubspec.lock* ./
RUN dart pub get

# Source Code kopieren
COPY . .

# Kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# Production Image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kompiliertes Binary kopieren
COPY --from=build /app/bin/server /app/bin/server

# Uploads-Verzeichnis erstellen
RUN mkdir -p /app/uploads

EXPOSE 8080

CMD ["/app/bin/server"]
