#!/usr/bin/env bash
# Prepara el proyecto para compilar.
#
# Las carpetas android/ e ios/ no se versionan: el scaffolding nativo congelado
# es la causa más habitual de que un proyecto Flutter deje de compilar meses
# después. Este script las regenera y deja el proyecto listo.
set -euo pipefail

echo "▸ Generando plataformas nativas…"
flutter create \
  --platforms=android,ios \
  --project-name estadistica_fundamental \
  --org com.estadisticafundamental \
  --description "Estadística Fundamental" \
  .

echo "▸ Descargando dependencias…"
flutter pub get

echo "▸ Generando iconos de la aplicación…"
dart run flutter_launcher_icons

echo "▸ Análisis estático…"
flutter analyze --no-fatal-infos || true

echo "▸ Pruebas…"
flutter test

cat <<'MSG'

Listo.

  flutter run                    ejecutar en un dispositivo
  flutter build apk --release    generar el APK instalable

El APK de release se firma con la clave de depuración: es válido para pruebas
de campo y no publicable en Google Play. Ver docs/05_Despliegue_y_CI_CD.md.
MSG
