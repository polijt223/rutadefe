# Ruta de Fe

App Android cristiana de reflexión espiritual y material de formación.

## Características principales

- **Autenticación**: Google (X/Twitter requiere configuración adicional de OAuth).
- **Seminarios y secciones**: Contenido organizado por capítulos/secciones con texto, PDFs, imágenes y links de YouTube.
- **Caché inteligente con versionado**: Los archivos se descargan una sola vez. Solo se vuelven a descargar si el administrador actualiza la versión. Se elimina la versión anterior automáticamente.
- **Quizzes**: Preguntas de opción múltiple y abiertas. Las abiertas se corrigen desde Cloud Functions con Gemini; los resultados se guardan por usuario y seminario.
- **Amigos y progreso**: Notas por sección con lectura entre amigos mutuos, ranking privado por seminario, progreso por sección, logros y certificado PDF.
- **Notificaciones push automáticas (por seminario)**:
  - Cada seminario tiene su propia bolsa de mini-reflexiones (texto y/o imagen).
  - El usuario activa las notificaciones por seminario y elige frecuencia (1h / 6h / 12h).
  - Se envían de forma cíclica sin repetir.
  - Cuando se agota la bolsa, se detiene y el usuario puede reiniciar el ciclo.
  - Historial accesible desde la campanita, segmentado por seminario (sin duplicados).
- **Panel de administrador** dentro de la misma app (rol `isAdmin` en Firestore).
- **Temas**: Light (borgoña + dorado) y Dark (blanco + dorado).
- **Apertura de archivos**: Descarga offline versionada. PDFs e imágenes se ven dentro de la app; también se pueden abrir con una aplicación del sistema.

## Estructura del proyecto

```
lib/
  models/          # Seminario, Seccion, MiniReflexion
  screens/         # Login, Home, Detalle, Visor, Notificaciones, Admin
  services/        # Auth, Firestore, LocalCache (SQLite + archivos)
  theme/           # Tema light/dark
functions/         # Cloud Function programada para enviar notificaciones
```

## Configuración Firebase

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
   - `seminarios/{id}/secciones/{id}/notas/{uid}` → notas privadas por sección
   - `usuarios/{uid}` → rol admin, token FCM, preferencias y puntajes privados
   - `perfilesPublicos/{uid}` → nombre y foto visibles solo al usuario y amigos mutuos
   - `codigosAmigo/{codigo}` → resolución privada de códigos de amistad
5. Despliega las reglas incluidas en el repositorio: `firebase deploy --only firestore:rules,storage`.
6. Añade las huellas SHA-1/SHA-256 Android en Firebase Authentication para Google Sign-In.

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
cd ..
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

El comando de secretos pedirá la clave de Gemini de forma interactiva. No la pongas en Flutter, `firebase_options.dart` ni en el repositorio: cualquier credencial incluida en una APK se puede extraer. Rota la clave que se haya agregado anteriormente al código cliente.

`sendScheduledReflections` corre cada hora y aplica la frecuencia individual (1h/6h/12h). Las funciones programadas requieren el plan Blaze y Cloud Scheduler habilitado.

## Notas importantes

- El login con X/Twitter todavía no está implementado.
- El primer administrador debe recibir `isAdmin: true` mediante Firebase Console o un proceso confiable del servidor; la app no permite autoasignarse ese rol.
- La lógica de caché usa SQLite + sistema de archivos del dispositivo.
- Las reglas del repositorio no se aplican hasta ejecutar el deploy indicado.

## Funciones pendientes

- Configurar y desplegar el secreto Gemini, las reglas y las Cloud Functions en Firebase.
- Implementar OAuth de X.
- Las notificaciones push por imagen dependen de que cada reflexión tenga `imagenUrl` pública/descargable.

---

**Ruta de Fe** — Camina, lee, reflexiona.
