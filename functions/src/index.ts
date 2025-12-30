import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as moment from "moment";

admin.initializeApp();

// Handle scheduled notifications (existing functionality)
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

// Handle admin notifications (immediate and scheduled)
exports.processAdminNotifications = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context: any) => {
    const now = moment.utc();
    
    // Get all user tokens
    const tokensSnapshot = await admin.firestore().collection("user_tokens").get();
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token).filter(Boolean);
    
    if (tokens.length === 0) {
      console.log("No user tokens found");
      return null;
    }

    // Process immediate notifications
    const immediateSnapshot = await admin.firestore()
      .collection("admin_notifications")
      .where("type", "==", "immediate")
      .where("sent", "==", false)
      .get();

    for (const doc of immediateSnapshot.docs) {
      const data = doc.data();
      try {
        const message = {
          notification: {
            title: data.title || "Notification",
            body: data.body || "",
          },
          data: data.data || {},
          tokens: data.tokens || tokens,
        };
        
        if (message.tokens.length > 0) {
          await admin.messaging().sendMulticast(message);
          console.log(`Sent immediate notification to ${message.tokens.length} users`);
        }
        
        await doc.ref.update({ 
          sent: true, 
          sentAt: now.toISOString() 
        });
      } catch (error) {
        console.error(`Error sending immediate notification ${doc.id}:`, error);
      }
    }

    // Process scheduled notifications
    const scheduledSnapshot = await admin.firestore()
      .collection("admin_notifications")
      .where("type", "==", "scheduled")
      .where("sent", "==", false)
      .get();

    for (const doc of scheduledSnapshot.docs) {
      const data = doc.data();
      const scheduledTime = moment.utc(data.scheduledTime);
      
      if (scheduledTime.isSameOrBefore(now)) {
        try {
          const message = {
            notification: {
              title: data.title || "Notification",
              body: data.body || "",
            },
            data: data.data || {},
            tokens: data.tokens || tokens,
          };
          
          if (message.tokens.length > 0) {
            await admin.messaging().sendMulticast(message);
            console.log(`Sent scheduled notification to ${message.tokens.length} users`);
          }
          
          await doc.ref.update({ 
            sent: true, 
            sentAt: now.toISOString() 
          });
        } catch (error) {
          console.error(`Error sending scheduled notification ${doc.id}:`, error);
        }
      }
    }

    return null;
  });