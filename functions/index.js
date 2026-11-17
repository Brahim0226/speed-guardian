const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// When an alert doc is created, push a notification to the partner (toUid).
exports.sendOverspeedPush = onDocumentCreated("alerts/{alertId}", async (event) => {
  const alert = event.data && event.data.data();
  if (!alert) return;

  const db = getFirestore();
  const [target, sender] = await Promise.all([
    db.collection("users").doc(alert.toUid).get(),
    db.collection("users").doc(alert.fromUid).get(),
  ]);

  // Only deliver between users who are still paired with each other.
  if (!target.exists || !sender.exists) return;
  if (target.get("partnerUid") !== alert.fromUid) return;

  const token = target.get("fcmToken");
  if (!token) return;

  await getMessaging().send({
    token,
    notification: {
      title: "⚠️ تنبيه سرعة",
      body: `شريكك يسوق بسرعة ${alert.speedKmh} كم/س والحد ${alert.limitKmh} كم/س`,
    },
    android: { priority: "high", notification: { channelId: "overspeed" } },
    apns: { payload: { aps: { sound: "default" } } },
  });
});
