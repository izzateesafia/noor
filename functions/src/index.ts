import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as moment from "moment";

admin.initializeApp();

exports.scheduledNotification = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context: any) => {
    const now = moment.utc();
    const snapshot = await admin.firestore()
      .collection("scheduled_notifications")
      .where("scheduledTime", "<=", now.toISOString())
      .where("sent", "==", null)
      .get();

    if (snapshot.empty) return null;

    const tokensSnapshot = await admin.firestore().collection("user_tokens").get();
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token).filter(Boolean);

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const message = {
        notification: {
          title: "Live Event Scheduled!",
          body: data.message || "Join the live event now!",
        },
        tokens,
      };
      if (tokens.length > 0) {
        await admin.messaging().sendMulticast(message);
      }
      await doc.ref.update({ sent: true, sentAt: now.toISOString() });
    }
    return null;
  });