# Ruta de Fe

App Android cristiana de reflexión espiritual y material de formación.

## Características principales

- **Autenticación**: Google (X/Twitter requiere configuración adicional de OAuth).
- **Seminarios y secciones**: Contenido organizado por capítulos/secciones con texto, PDFs, imágenes y links de YouTube.
- **Caché inteligente con versionado**: Los archivos se descargan una sola vez. Solo se vuelven a descargar si el administrador actualiza la versión. Se elimina la versión anterior automáticamente.
- **Notificaciones push automáticas (por seminario)**:
  - Cada seminario tiene su propia bolsa de mini-reflexiones (texto y/o imagen).
  - El usuario activa las notificaciones por seminario y elige frecuencia (1h / 6h / 12h).
  - Se envían de forma cíclica sin repetir.
  - Cuando se agota la bolsa, se detiene y el usuario puede reiniciar el ciclo.
  - Historial accesible desde la campanita, segmentado por seminario (sin duplicados).
- **Panel de administrador** dentro de la misma app (rol `isAdmin` en Firestore).
- **Temas**: Light (borgoña + dorado) y Dark (blanco + dorado).
- **Apertura de archivos**: Dentro de la app o con apps externas del sistema.

## Estructura del proyecto

```
lib/
  models/          # Seminario, Seccion, MiniReflexion
  screens/         # Login, Home, Detalle, Visor, Notificaciones, Admin
  services/        # Auth, Firestore, LocalCache (SQLite + archivos)
  theme/           # Tema light/dark
functions/         # Cloud Function programada para enviar notificaciones
```

## Configuración inicial (Firebase - Plan Spark gratis)

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com).
2. Activa:
   - Authentication → Google (y Twitter/X si lo deseas).
   - Firestore Database.
   - Storage.
   - Cloud Messaging.
3. Descarga `google-services.json` y colócalo en `android/app/`.
4. En Firestore crea la estructura:
   - `seminarios/{id}` → nombre, descripcion, activo, creadoEn
   - `seminarios/{id}/secciones/{id}` → titulo, contenidoTexto, orden, version, archivos[], youtubeUrl
   - `seminarios/{id}/miniReflexiones/{id}` → texto, imagenUrl, orden
   - `usuarios/{uid}` → isAdmin (bool), fcmToken, notificaciones: { seminarioId: { enabled, frequency, lastSentIndex, cycleCompleted } }
5. Reglas de seguridad recomendadas (ajustar según necesidad):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /seminarios/{seminario} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.isAdmin == true;
       }
       match /usuarios/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

## Compilar y ejecutar

```bash
flutter pub get
flutter run
```

Para generar APK:
```bash
flutter build apk --release
```

## Cloud Functions (notificaciones automáticas)

```bash
cd functions
npm install
firebase deploy --only functions
```

La función `sendScheduledReflections` corre cada 60 minutos y respeta las preferencias de cada usuario.

## Notas importantes

- El login con X/Twitter está preparado pero requiere completar la configuración OAuth en Firebase y el paquete correspondiente.
- El panel de administrador tiene la estructura básica. Los formularios de creación/edición y subida de archivos a Storage se pueden expandir fácilmente.
- La lógica de caché usa SQLite + sistema de archivos del dispositivo.
- Las notificaciones ricas (con imagen) son soportadas por FCM en Android.

## Próximos pasos recomendados

1. Completar formularios del panel admin.
2. Implementar completamente el login con X.
3. Añadir visores internos de PDF e imágenes (actualmente se abre con el sistema).
4. Mejorar la lógica de frecuencia en la Cloud Function (guardar `lastSentAt`).
5. Añadir el logo real en los assets.

---

**Ruta de Fe** — Camina, lee, reflexiona.
