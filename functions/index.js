/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

const fetch = require("node-fetch");

const functions = require("firebase-functions");
const FCM_SERVER_KEY = functions.config().fcm.server_key;

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// FCM Notifications for Djassa CI
exports.sendPaymentConfirmed = functions.https.onRequest(async (req, res) => {
  const { fcmToken, orderId } = req.body;
  
  if (!fcmToken || !FCM_SERVER_KEY) {
    return res.status(400).json({ error: 'FCM token or server key missing' });
  }

  const message = {
    notification: {
      title: '✅ Paiement Confirmé!',
      body: `Votre commande #${orderId} est payée! Préparez-vous à recevoir vos produits.`,
    },
    data: {
      type: 'payment_confirmed',
      orderId: orderId.toString(),
    },
    token: fcmToken,
  };

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    if (response.ok) {
      logger.info('Payment confirmed notification sent successfully');
      res.json({ success: true });
    } else {
      logger.error('FCM send failed:', await response.text());
      res.status(500).json({ error: 'Notification send failed' });
    }
  } catch (error) {
    logger.error('FCM send error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

exports.sendOrderDelivered = functions.https.onRequest(async (req, res) => {
  const { fcmToken, orderId } = req.body;

  if (!fcmToken || !FCM_SERVER_KEY) {
    return res.status(400).json({ error: 'FCM token or server key missing' });
  }

  const message = {
    notification: {
      title: '📦 Commande Livrée!',
      body: `Votre commande #${orderId} est en route ou livrée!`,
    },
    data: {
      type: 'order_delivered',
      orderId: orderId.toString(),
    },
    token: fcmToken,
  };

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    if (response.ok) {
      logger.info('Order delivered notification sent successfully');
      res.json({ success: true });
    } else {
      logger.error('FCM send failed:', await response.text());
      res.status(500).json({ error: 'Notification send failed' });
    }
  } catch (error) {
    logger.error('FCM send error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

exports.sendNewClient = functions.https.onRequest(async (req, res) => {
  const { fcmToken, sellerName } = req.body;

  if (!fcmToken || !FCM_SERVER_KEY) {
    return res.status(400).json({ error: 'FCM token or server key missing' });
  }

  const message = {
    notification: {
      title: '🎉 Nouveau Client!',
      body: `Un nouveau client a commandé chez ${sellerName}!`,
    },
    data: {
      type: 'new_client',
    },
    token: fcmToken,
  };

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    if (response.ok) {
      logger.info('New client notification sent successfully');
      res.json({ success: true });
    } else {
      logger.error('FCM send failed:', await response.text());
      res.status(500).json({ error: 'Notification send failed' });
    }
  } catch (error) {
    logger.error('FCM send error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

