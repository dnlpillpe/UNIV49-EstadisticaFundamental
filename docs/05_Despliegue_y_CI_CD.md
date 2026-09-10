# 05 · Despliegue y CI/CD

---

## 1. Requisitos

- Flutter 3.19+ (canal `stable`), Dart 3.3+
- JDK 17 (Android Gradle Plugin 8.x lo exige)
- Android SDK con plataforma 34 o superior
- Para iOS: macOS con Xcode 15+ y CocoaPods

---

## 2. Compilación local

Las carpetas `android/` e `ios/` **no están en el repositorio**: se regeneran.

```bash
git clone <repositorio>
cd estadistica_fundamental

# 1 · Generar las plataformas nativas
flutter create --platforms=android,ios \
  --project-name estadistica_fundamental \
  --org com.estadisticafundamental \
  --description "Estadística Fundamental" .

# 2 · Dependencias
flutter pub get

# 3 · Iconos (escribe los mipmaps de Android y el AppIcon de iOS)
dart run flutter_launcher_icons

# 4 · Verificación
flutter analyze --no-fatal-infos
flutter test

# 5 · Ejecutar o compilar
flutter run
flutter build apk --release
```

**Por qué no se versionan las plataformas.** El scaffolding nativo congelado en
un repositorio es la causa más habitual de que un proyecto Flutter deje de
compilar meses después, por desajustes entre Gradle, el Android Gradle Plugin y
el SDK. Regenerarlo elimina esa clase entera de fallos. El precio es que
cualquier personalización nativa debe declararse fuera de esas carpetas; en este
proyecto la única es el icono, y se resuelve con `flutter_launcher_icons`.

### Regenerar el icono desde el diseño

```bash
pip install pillow
python3 tool/generate_icon.py     # regenera assets/icon/*.png
dart run flutter_launcher_icons   # y de ahí a las plataformas
```

El script reproduce en Pillow el mismo dibujo que `BrandMarkPainter` pinta dentro
de la app. Si se cambia uno, hay que cambiar el otro.

---

## 3. Workflows

| Workflow | Disparador | Qué hace |
|---|---|---|
| `ci.yml` | push y pull request en `main`, `master`, `develop` | Formato (informativo), análisis estático, suite completa y cobertura |
| `build_apk.yml` | push a `main`/`master`, etiquetas `v*`, manual | APK por ABI y universal, artefacto de 30 días y release en etiqueta |

Ambos empiezan generando las plataformas nativas y restaurando después el código
del repositorio con `git checkout -- lib pubspec.yaml analysis_options.yaml test
assets`, como red de seguridad por si alguna versión de `flutter create` tocara
archivos del proyecto.

### Publicar una versión

```bash
# 1 · Subir la versión en pubspec.yaml   (version: 1.1.0+2)
# 2 · Commit y etiqueta
git commit -am "Versión 1.1.0"
git tag v1.1.0
git push origin main --tags
```

El workflow compila, adjunta los APK a la release y genera las notas.

### Compilación manual

Actions → «Compilar APK» → *Run workflow* → elegir `release` o `debug`.

---

## 4. Firma

### Estado actual

El APK de release se firma con **la clave de depuración** que genera
`flutter create`. Consecuencias:

- ✅ Instalable en cualquier dispositivo Android para pruebas de campo.
- ❌ **No publicable en Google Play.**
- ❌ No actualizable sobre una instalación firmada con otra clave.

Es una decisión consciente para el MVP: permite distribuir el APK a un grupo
piloto sin gestionar secretos, y la firma real se añade cuando haya decisión de
publicar.

### Pasos para la firma real

**1 · Generar el almacén de claves** (una sola vez; guardarlo fuera del
repositorio y no perderlo, porque sin él no se puede actualizar la app):

```bash
keytool -genkey -v -keystore ~/estadistica-fundamental.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias estadistica
```

**2 · Cargarlo como secretos de GitHub** (Settings → Secrets and variables →
Actions):

```bash
base64 -w0 ~/estadistica-fundamental.jks   # → secreto KEYSTORE_BASE64
```

| Secreto | Contenido |
|---|---|
| `KEYSTORE_BASE64` | El `.jks` codificado en base64 |
| `KEYSTORE_PASSWORD` | Contraseña del almacén |
| `KEY_PASSWORD` | Contraseña de la clave |
| `KEY_ALIAS` | `estadistica` |

**3 · Añadir al workflow**, después de generar las plataformas nativas:

```yaml
- name: Restaurar el almacén de claves
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.jks
    cat > android/key.properties <<PROPS
    storePassword=${{ secrets.KEYSTORE_PASSWORD }}
    keyPassword=${{ secrets.KEY_PASSWORD }}
    keyAlias=${{ secrets.KEY_ALIAS }}
    storeFile=release.jks
    PROPS

- name: Configurar la firma en Gradle
  run: |
    python3 - <<'PY'
    from pathlib import Path
    p = Path("android/app/build.gradle")
    if not p.exists():
        p = Path("android/app/build.gradle.kts")
    s = p.read_text()
    # Sustituir la firma de depuración por la de release.
    s = s.replace("signingConfig = signingConfigs.debug",
                  "signingConfig = signingConfigs.release")
    s = s.replace("signingConfig signingConfigs.debug",
                  "signingConfig signingConfigs.release")
    p.write_text(s)
    PY
```

Y declarar el `signingConfigs.release` que lee `key.properties`, siguiendo la
[guía oficial de Flutter](https://docs.flutter.dev/deployment/android#signing-the-app).

> `android/key.properties` y cualquier `.jks` **nunca** deben entrar en el
> repositorio. Ya están cubiertos por el `.gitignore` que ignora `android/`
> entera.

---

## 5. Distribución

### App Bundle para Google Play

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Play exige AAB, no APK. El workflow genera APK porque el objetivo del MVP es la
prueba de campo directa; para publicar hay que añadir un paso con este comando.

### iOS

```bash
flutter build ipa --release
```

Requiere macOS, cuenta de desarrollador de Apple y perfiles de
aprovisionamiento. Fuera del alcance del MVP.

### Instalación directa del APK

Se descarga el APK que corresponda al dispositivo:

- `arm64-v8a` — prácticamente todos los móviles actuales
- `armeabi-v7a` — dispositivos antiguos
- `x86_64` — emuladores
- Sin sufijo — universal, funciona en todos, ocupa más

En el dispositivo hay que permitir la instalación desde orígenes desconocidos.

---

## 6. Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| `No such file or directory: android/` | Falta ejecutar `flutter create --platforms=android,ios .` |
| Gradle falla por la versión de Java | Usar JDK 17: `flutter config --jdk-dir <ruta>` |
| El icono no cambia | Ejecutar `dart run flutter_launcher_icons` **después** de `flutter create` |
| Los tests de contenido fallan al arrancar | Se ejecutan desde la raíz del proyecto: `flutter test`, no desde `test/` |
| `flutter analyze` avisa de `withValues` | Requiere Flutter 3.27+. Actualizar el canal `stable` |
| El APK de release no se instala sobre otro anterior | Firmas distintas: desinstalar primero |

---

## 7. Lista de verificación antes de publicar

- [ ] `flutter analyze` sin errores
- [ ] `flutter test` en verde, incluida la suite de integridad de contenido
- [ ] Versión subida en `pubspec.yaml` (`version` y `build number`)
- [ ] Icono regenerado si cambió el diseño
- [ ] Probado en un dispositivo físico, en tema claro y oscuro
- [ ] Probado **en modo avión**: la app debe funcionar entera
- [ ] Probado con el tamaño de fuente del sistema al máximo
- [ ] Revisado que «Acerca de» declara el método de cálculo vigente
