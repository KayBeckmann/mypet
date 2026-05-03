# Flutter Android - Tierbesitzer App
# Build-Kontext: Repo-Root (enthält shared/ und android_owner/)
FROM ghcr.io/cirruslabs/flutter:stable AS build

# API-URL konfigurierbar via docker-compose build-arg oder --build-arg
# Default: 10.0.2.2 ist der Android-Emulator-Host
ARG API_BASE_URL=http://10.0.2.2:8080

WORKDIR /app

# Android SDK Lizenzen akzeptieren und benötigte Komponenten installieren
# Retry-Schleife wegen TLS-Abbrüchen (Crostini-Umgebung)
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses 2>&1 || true
RUN for i in 1 2 3 4 5; do \
      ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
        "ndk;28.2.13676358" "build-tools;35.0.0" 2>&1 \
      && echo "SDK-Installation erfolgreich (Versuch $i)" && break \
      || echo "Versuch $i fehlgeschlagen, warte 5s..." && sleep 5; \
    done \
 && ls ${ANDROID_SDK_ROOT}/ndk/28.2.13676358 > /dev/null 2>&1 \
 && echo "NDK 28.2 erfolgreich installiert" \
 || (echo "NDK-Installation fehlgeschlagen nach 5 Versuchen" && exit 1)

# Gradle-Distribution vorab laden (TLS 1.2, Retry) — umgeht TLS-Inspection beim Wrapper-Download
RUN for i in 1 2 3 4 5; do \
      curl --tlsv1.2 --retry 3 --retry-delay 5 -L \
        -o /tmp/gradle-dist.zip \
        https://services.gradle.org/distributions/gradle-8.14-all.zip \
      && echo "Gradle-Download erfolgreich (Versuch $i)" && break \
      || echo "Versuch $i fehlgeschlagen, warte 10s..." && sleep 10; \
    done \
 && test -f /tmp/gradle-dist.zip \
 || (echo "Gradle-Download fehlgeschlagen nach 5 Versuchen" && exit 1)

# Shared-Paket + Manifest zuerst kopieren
COPY shared/ /app/shared/
COPY android_owner/pubspec.yaml android_owner/pubspec.lock* /app/android_owner/
WORKDIR /app/android_owner
RUN flutter pub get

# Restlichen Quellcode kopieren
COPY android_owner/ /app/android_owner/

# Gradle-Wrapper auf lokal heruntergeladene Datei umleiten (kein HTTPS beim Wrapper-Start)
RUN sed -i 's|distributionUrl=.*|distributionUrl=file\:///tmp/gradle-dist.zip|' \
    android/gradle/wrapper/gradle-wrapper.properties

# Gradle-Konfiguration: TLS 1.2 erzwingen für Plugin- und Dependency-Downloads
# JAVA_TOOL_OPTIONS gilt für den Gradle-Wrapper-Prozess selbst
# org.gradle.jvmargs (in gradle.properties) gilt für den Gradle-Daemon
ENV GRADLE_OPTS="-Xmx4g -Dorg.gradle.daemon=false \
  -Dhttps.protocols=TLSv1.2 \
  -Djdk.tls.client.protocols=TLSv1.2 \
  -Dcom.sun.net.ssl.checkRevocation=false" \
    JAVA_TOOL_OPTIONS="-Dhttps.protocols=TLSv1.2 -Djdk.tls.client.protocols=TLSv1.2"

# APK bauen — Retry-Schleife wegen möglicher TLS-Abbrüche bei Maven/Google-Downloads
RUN for i in 1 2 3; do \
      flutter build apk --release \
        --dart-define=API_BASE_URL=${API_BASE_URL} \
        --no-tree-shake-icons \
      && echo "APK-Build erfolgreich (Versuch $i)" && break \
      || echo "Versuch $i fehlgeschlagen, starte neu..." && sleep 15; \
    done \
 && test -f build/app/outputs/flutter-apk/app-release.apk \
 || (echo "APK-Build nach 3 Versuchen fehlgeschlagen" && exit 1)

# APK in zugängliches Verzeichnis kopieren
RUN mkdir -p /output && \
    cp build/app/outputs/flutter-apk/app-release.apk /output/mypet-owner.apk

# Finales Image — nur APK
FROM alpine:3.19
COPY --from=build /output/mypet-owner.apk /app/mypet-owner.apk
CMD ["sh", "-c", "echo 'APK: /app/mypet-owner.apk' && ls -lh /app/"]
