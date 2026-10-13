const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { defineSecret } = require('firebase-functions/params');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const geminiApiKey = defineSecret('GEMINI_API_KEY');

exports.gradeQuizAnswer = onCall({ secrets: [geminiApiKey], maxInstances: 3 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Debes iniciar sesión para corregir una respuesta.');
  }

  const { seminarioId, seccionId, quizId, preguntaId, respuestaUsuario } = request.data || {};
  if ([seminarioId, seccionId, quizId, preguntaId].some((id) => typeof id !== 'string' || !id) ||
      typeof respuestaUsuario !== 'string' || respuestaUsuario.trim().length === 0 ||
      respuestaUsuario.length > 5000) {
    throw new HttpsError('invalid-argument', 'La respuesta o los identificadores del quiz no son válidos.');
  }

  const userId = request.auth.uid;
  const day = new Date().toISOString().slice(0, 10);
  const quotaRef = db.collection('_geminiDailyUsage').doc(userId);
  const withinQuota = await db.runTransaction(async (transaction) => {
    const usage = (await transaction.get(quotaRef)).data() || {};
    const count = usage.day === day ? usage.count || 0 : 0;
    if (count >= 60) return false;
    transaction.set(quotaRef, { day, count: count + 1, updatedAt: FieldValue.serverTimestamp() });
    return true;
  });
  if (!withinQuota) {
    throw new HttpsError('resource-exhausted', 'Alcanzaste el límite diario de evaluaciones.');
  }

  const sectionRef = db.collection('seminarios').doc(seminarioId).collection('secciones').doc(seccionId);
  const quizRef = sectionRef.collection('quiz').doc(quizId);
  const questionRef = quizRef.collection('preguntas').doc(preguntaId);
  const [sectionSnap, quizSnap, questionSnap, questionsSnap] = await Promise.all([
    sectionRef.get(),
    quizRef.get(),
    questionRef.get(),
    quizRef.collection('preguntas').get(),
  ]);
  if (!sectionSnap.exists || !quizSnap.exists || !questionSnap.exists || questionsSnap.empty) {
    throw new HttpsError('not-found', 'No se encontró la pregunta del quiz.');
  }

  const question = questionSnap.data();
  const statement = question.enunciado;
  if (typeof statement !== 'string' || statement.length > 2000) {
    throw new HttpsError('failed-precondition', 'La pregunta no contiene un enunciado válido.');
  }

  let grade;
  if (question.tipo === 'multiple') {
    const answerSnap = await questionRef.collection('respuestas').doc('clave').get();
    const correctAnswer = answerSnap.data()?.respuestaCorrecta;
    if (typeof correctAnswer !== 'string') {
      throw new HttpsError('failed-precondition', 'La pregunta no tiene configurada su respuesta.');
    }
    const isCorrect = respuestaUsuario.trim().toLocaleLowerCase() === correctAnswer.trim().toLocaleLowerCase();
    grade = {
      nota: isCorrect ? 100 : 0,
      correcta: isCorrect,
      comentario: isCorrect ? 'Respuesta correcta.' : 'Revisa el material y vuelve a intentarlo en otro momento.',
    };
  } else {
    const materialSeccion = sectionSnap.data()?.contenidoTexto || '';
    if (materialSeccion.length > 15000) {
      throw new HttpsError('failed-precondition', 'El material excede el tamaño permitido para evaluación.');
    }
    const prompt = `
Eres un corrector claro y respetuoso de un seminario cristiano.
Evalúa la respuesta basándote en el material. Sé justo, concreto y pastoral.
Máximo cuatro oraciones en el comentario. Devuelve únicamente JSON válido con:
{"nota":0,"comentario":"...","correcta":false}

MATERIAL:\n${materialSeccion}
PREGUNTA:\n${statement}
RESPUESTA DEL ALUMNO:\n${respuestaUsuario}
`;

  try {
    const response = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiApiKey.value(),
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' },
        }),
      },
    );

    if (!response.ok) {
      console.error('Gemini request failed with status:', response.status);
      throw new HttpsError('unavailable', 'El corrector no está disponible temporalmente.');
    }

      const payload = await response.json();
      const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== 'string') throw new Error('Gemini returned no response text.');
      grade = JSON.parse(text);
      if (!Number.isFinite(grade.nota) || typeof grade.comentario !== 'string' ||
          typeof grade.correcta !== 'boolean') {
        throw new Error('Gemini returned an invalid grade.');
      }
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error('Unable to grade quiz answer:', error);
      throw new HttpsError('unavailable', 'No se pudo corregir la respuesta. Inténtalo de nuevo.');
    }
  }

  grade.nota = Math.max(0, Math.min(100, Math.round(grade.nota)));
  grade.comentario = grade.comentario.slice(0, 1200);

  const scoreRef = db.collection('usuarios').doc(userId).collection('puntajes').doc(seminarioId);
  const scoreUpdate = await db.runTransaction(async (transaction) => {
    const scoreData = (await transaction.get(scoreRef)).data() || {};
    const quizzes = { ...(scoreData.quizzes || {}) };
    const answersByQuiz = { ...(scoreData.respuestas || {}) };
    const answers = { ...(answersByQuiz[quizId] || {}) };
    if (Object.prototype.hasOwnProperty.call(answers, preguntaId)) {
      return { inserted: false, completed: false };
    }
    answers[preguntaId] = grade.nota;
    answersByQuiz[quizId] = answers;
    const values = Object.values(answers).map(Number);
    const completed = values.length >= questionsSnap.size;
    if (completed) {
      quizzes[quizId] = Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
    }
    const quizScores = Object.values(quizzes).map(Number);
    const promedio = quizScores.length === 0
      ? 0
      : Math.round(quizScores.reduce((sum, value) => sum + value, 0) / quizScores.length);
    transaction.set(scoreRef, {
      quizzes,
      respuestas: answersByQuiz,
      promedio,
      totalQuizzes: quizScores.length,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { inserted: true, completed };
  });
  if (!scoreUpdate.inserted) {
    throw new HttpsError('already-exists', 'Esta pregunta ya fue respondida.');
  }

  return {...grade, quizCompleted: scoreUpdate.completed};
});

exports.migrateQuizAnswerKeys = onCall({ maxInstances: 1 }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
  const user = await db.collection('usuarios').doc(request.auth.uid).get();
  if (user.data()?.isAdmin !== true) {
    throw new HttpsError('permission-denied', 'Solo un administrador puede migrar quizzes.');
  }

  const seminars = await db.collection('seminarios').get();
  let migrated = 0;
  for (const seminar of seminars.docs) {
    const sections = await seminar.ref.collection('secciones').get();
    for (const section of sections.docs) {
      const quizzes = await section.ref.collection('quiz').get();
      for (const quiz of quizzes.docs) {
        const questions = await quiz.ref.collection('preguntas').get();
        for (const question of questions.docs) {
          const data = question.data();
          if (typeof data.respuestaCorrecta !== 'string' || !data.respuestaCorrecta) continue;
          await question.ref.collection('respuestas').doc('clave').set({
            respuestaCorrecta: data.respuestaCorrecta,
          });
          await question.ref.update({ respuestaCorrecta: FieldValue.delete() });
          migrated++;
        }
      }
    }
  }
  return { migrated };
});

/**
 * Cloud Function programada (cron) que envía las mini-reflexiones.
 * Se ejecuta cada hora. Internamente respeta la frecuencia de cada usuario
 * (1h / 6h / 12h) y no repite hasta que se reinicie el ciclo.
 *
 * Desplegar con: firebase deploy --only functions
 * Programar en Cloud Scheduler o usar functions.pubsub.schedule
 */
exports.sendScheduledReflections = onSchedule('every 60 minutes', async (event) => {
    const usersSnap = await db.collection('usuarios').get();

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const notificaciones = userData.notificaciones || {};
      const fcmToken = userData.fcmToken;

      if (!fcmToken) continue;

      for (const [seminarioId, prefs] of Object.entries(notificaciones)) {
        if (!prefs.enabled || prefs.cycleCompleted) continue;

        const frequencyMs = {
          '1h': 60 * 60 * 1000,
          '6h': 6 * 60 * 60 * 1000,
          '12h': 12 * 60 * 60 * 1000,
        }[prefs.frequency] || 6 * 60 * 60 * 1000;
        const lastSentAt = prefs.lastSentAt;
        const lastSentMillis = lastSentAt && typeof lastSentAt.toMillis === 'function'
          ? lastSentAt.toMillis()
          : 0;
        if (Date.now() - lastSentMillis < frequencyMs) continue;

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
            [`notificaciones.${seminarioId}.enabled`]: false,
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
            texto: reflexion.texto || 'Nueva reflexión',
            imagenUrl: reflexion.imagenUrl || '',
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
            [`notificaciones.${seminarioId}.lastSentAt`]: FieldValue.serverTimestamp(),
            [`notificaciones.${seminarioId}.cycleCompleted`]: currentIndex + 1 >= reflexiones.length,
            [`notificaciones.${seminarioId}.enabled`]: currentIndex + 1 < reflexiones.length,
          });

          // Guardar en historial del usuario (opcional, también se puede hacer en el cliente)
          console.log(`Enviada reflexión ${reflexionId} a ${userDoc.id}`);
        } catch (err) {
          console.error('Error enviando notificación:', err);
          if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']
              .includes(err.code)) {
            await userDoc.ref.update({fcmToken: FieldValue.delete()});
          }
        }
      }
    }

    return null;
});
