# GitHub Actions CI/CD

Este proyecto incluye workflows de GitHub Actions para compilar automa ticamente la aplicacion para iOS y Android.

## Workflows Disponibles

### 1. build_ios.yml - Build iOS (Production)
- Compila la IPA para dispositivos iOS reales
- Requiere certificados de firma de Apple
- Genera archivo ZIP con la app compilada

### 2. build_ios_simulator.yml - Build iOS Simulator
- Compila la app para el simulador de iOS
- No requiere certificados de firma
- Ideal para pruebas rapidas

### 3. build_all.yml - Build All Platforms
- Compila Android (APK) + iOS (Simulator)
- Ejecucion en paralelo

## Configuracion Requerida

### Para compilar iOS con firma (Producci n):

Necesitas configurar estos secrets en tu repositorio de GitHub:

1. Ve a **Settings > Secrets and variables > Actions**
2. Agrega los siguientes secrets:

| Secret | Descripcion |
|--------|-------------|
| `SSH_KEY` | Clave privada SSH (para acceso a repos privados si es necesario) |
| `KEYCHAIN_PASSWORD` | Contrase a del keychain de macOS |
| `SIGNING_KEY` | Certificado de firma (base64 encoded) |
| `TEAM_ID` | Tu Apple Team ID |
| `BUNDLE_ID` | Identificador del bundle (ej: com.miapp.granja) |

### Para generar los certificados:

```bash
# 1. En Mac, crea el certificado en tu cuenta de Apple Developer
# 2. Descarga el certificado y conviertelo a P12
openssl pkcs12 -export -in Certificates.p12 -out signing_key.p12

# 3. Codifica en base64
base64 -i signing_key.p12 -o signing_key.txt
```

## Uso

### Opcion 1: Desde GitHub Actions
1. Sube el codigo a GitHub
2. Ve a la pest a **Actions**
3. Selecciona el workflow deseado
4. Click en **Run workflow**

### Opcion 2: Trigger automatico
- Push a `main` o `master` iniciara el build automaticamente

## Descargar la IPA compilada

1. Ve a **Actions** > Select workflow run
2. Busca el artifact **ios-ipa** o **ios-app**
3. Descarga el ZIP
4. Descomprime y tendras el archivo .app o .ipa

## Notas Importantes

- La compilacion de iOS solo funciona en runners de macOS
- Los minutos de GitHub Actions son limitados (2000/min mes gratis)
- Para produccion real, considera usar [Codemagic](https://codemagic.io) o [Bitrise](https://bitrise.io)

## Solucion de Problemas

### Error: "No code signing certificate"
La app se compila pero no esta firmada. Usa `--no-codesign` o configura los certificados.

### Error: "CocoaPods required"
Asegurate de que `pod install` se ejecute en el directorio `ios/`.

### Error: "Flutter not found"
El action `subosito/flutter-action` debe descargar Flutter automaticamente.