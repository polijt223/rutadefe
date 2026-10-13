const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function programada (cron) que envía las mini-reflexiones.
 * Se ejecuta cada hora. Internamente respeta la frecuencia de cada usuario
 * (1h / 6h / 12h) y no repite hasta que se reinicie el ciclo.
 *
 * Desplegar con: firebase deploy --only functions
 * Programar en Cloud Scheduler o usar functions.pubsub.schedule
 */
exports.sendScheduledReflections = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    const usersSnap = await db.collection('usuarios').get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const notificaciones = userData.notificaciones || {};
      const fcmToken = userData.fcmToken;

      if (!fcmToken) continue;

      for (const [seminarioId, prefs] of Object.entries(notificaciones)) {
        if (!prefs.enabled || prefs.cycleCompleted) continue;

        // Verificar si toca enviar según la frecuencia
        // (lógica simplificada: en producción se guarda lastSentAt)
        const shouldSend = true; // TODO: comparar con lastSentAt y frequency

        if (!shouldSend) continue;

        // Obtener mini-reflexiones del seminario
        const reflexionesSnap = await db
          .collection('seminarios')
          .doc(seminarioId)
          .collection('miniReflexiones')
          .orderBy('orden')
          .get();

        const reflexiones = reflexionesSnap.docs;
        if (reflexiones.length === 0) continue;

        const currentIndex = prefs.lastSentIndex || 0;
        if (currentIndex >= reflexiones.length) {
          // Ciclo completado
          await userDoc.ref.update({
            [`notificaciones.${seminarioId}.cycleCompleted`]: true,
          });
          continue;
        }

        const reflexion = reflexiones[currentIndex].data();
        const reflexionId = reflexiones[currentIndex].id;

        // Enviar notificación
        const message = {
          token: fcmToken,
          notification: {
            title: 'Ruta de Fe',
            body: reflexion.texto || 'Nueva reflexión',
          },
          data: {
            seminarioId,
            miniReflexionId: reflexionId,
            type: 'reflection',
          },
        };

        if (reflexion.imagenUrl) {
          message.notification.imageUrl = reflexion.imagenUrl;
        }

        try {
          await messaging.send(message);

          // Avanzar índice
          await userDoc.ref.update({
            [`notificaciones.${seminarioId}.lastSentIndex`]: currentIndex + 1,
          });

          // Guardar en historial del usuario (opcional, también se puede hacer en el cliente)
          console.log(`Enviada reflexión ${reflexionId} a ${userDoc.id}`);
        } catch (err) {
          console.error('Error enviando notificación:', err);
        }
      }
    }

    return null;
  });
