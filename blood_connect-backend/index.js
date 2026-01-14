const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const admin = require("firebase-admin");
require("dotenv").config();
const admin = require("firebase-admin");z

const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://bloodconnect-4md03.firebaseio.com"
});


const app = express();
app.use(cors());
app.use(bodyParser.json());

if (process.env.GCP_SA_KEY) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.GCP_SA_KEY)),
  });
} else {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const API_KEY = process.env.API_KEY || "replace-with-strong-secret";

function requireApiKey(req, res, next) {
  const key = req.header("x-api-key");
  if (!key || key !== API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}

function validateArray(arr) {
  return Array.isArray(arr) && arr.length > 0;
}

function unique(array) {
  return [...new Set(array)];
}

async function getAllTokensForUser(userId) {
  const tokensSnap = await admin
    .firestore()
    .collection("users")
    .doc(userId)
    .collection("tokens")
    .get();
  return tokensSnap.docs.map((d) => d.id);
}

async function getAllAdminTokens() {
  const adminsSnap = await admin
    .firestore()
    .collection("users")
    .where("role", "==", "Admin")
    .get();

  const tokens = [];
  for (const doc of adminsSnap.docs) {
    const userId = doc.id;
    const userTokens = await getAllTokensForUser(userId);
    tokens.push(...userTokens);
  }
  return unique(tokens);
}

async function logDonorActivity(donorId, action, bloodType, location) {
  await admin.firestore().collection("donorHistory").add({
    donorId,
    action,
    bloodType,
    location,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

app.get("/", (req, res) => {
  res.send("BloodConnect backend is running");
});

app.post("/sendNotification", requireApiKey, async (req, res) => {
  try {
    const {
      requestId,
      donorId,
      tokens,
      title,
      body,
      bloodType,
      location,
      type = "request_update",
    } = req.body;

    if (!validateArray(tokens)) {
      return res.status(400).send({ error: "tokens array required" });
    }

    const logKey = `${requestId}_donor_to_recipient`;
    const alreadySent = await admin
      .firestore()
      .collection("notificationsLog")
      .doc(logKey)
      .get();

    if (alreadySent.exists) {
      return res.status(200).send({ message: "Notification already sent" });
    }

    const uniqueTokens = unique(tokens);

    const message = {
      tokens: uniqueTokens,
      notification: { title, body },
    };

    const response = await admin.messaging().sendMulticast(message);

    await admin.firestore().collection("notificationsLog").doc(logKey).set({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      count: uniqueTokens.length,
      type,
    });

    const usersSnap = await admin.firestore().collection("users").get();
    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      for (const token of uniqueTokens) {
        const tokenDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .collection("tokens")
          .doc(token)
          .get();
        if (tokenDoc.exists) {
          await admin.firestore().collection("notifications").add({
            userId,
            title,
            body,
            type,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }

    if (donorId) {
      await logDonorActivity(donorId, "Responded to Request", bloodType, location);
    }

    res.status(200).send(response);
  } catch (err) {
    console.error("Notification error:", err);
    res
      .status(500)
      .send({ error: "Failed to send notification", details: err.message });
  }
});

app.post("/notifyAdmins", requireApiKey, async (req, res) => {
  try {
    const { requestId, bloodType, location } = req.body;

    if (!requestId || !bloodType || !location) {
      return res
        .status(400)
        .json({ error: "requestId, bloodType, and location are required" });
    }

    const logKey = `${requestId}_recipient_to_admin`;
    const alreadySent = await admin
      .firestore()
      .collection("notificationsLog")
      .doc(logKey)
      .get();
    if (alreadySent.exists) {
      return res.status(200).send({ message: "Notification already sent" });
    }

    const adminTokens = await getAllAdminTokens();

    if (adminTokens.length > 0) {
      const title = "New Blood Request";
      const body = `Blood Type: ${bloodType} — Location: ${location}`;
      const type = "system";

      const message = {
        tokens: adminTokens,
        notification: { title, body },
      };

      const response = await admin.messaging().sendMulticast(message);

      await admin.firestore().collection("notificationsLog").doc(logKey).set({
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        count: adminTokens.length,
        type,
      });

      const adminsSnap = await admin
        .firestore()
        .collection("users")
        .where("role", "==", "Admin")
        .get();
      for (const doc of adminsSnap.docs) {
        await admin.firestore().collection("notifications").add({
          userId: doc.id,
          title,
          body,
          type,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      res.status(200).send(response);
    } else {
      res.status(200).send({ message: "No admin tokens found" });
    }
  } catch (error) {
    console.error("Error notifying admins:", error);
    res.status(500).send({ error: "Failed to notify admins" });
  }
});

app.post("/donorAvailable", requireApiKey, async (req, res) => {
  try {
    const { donorId, bloodType, location } = req.body;
    if (!donorId) return res.status(400).json({ error: "donorId is required" });

    await logDonorActivity(donorId, "Marked Available", bloodType, location);

    res.status(200).send({ message: "Donor availability logged successfully" });
  } catch (error) {
    console.error("Error logging donor availability:", error);
    res.status(500).send({ error: "Failed to log donor availability" });
  }
});

app.get("/admin/requests", requireApiKey, async (req, res) => {
  try {
    const snapshot = await admin
      .firestore()
      .collection("requests")
      .orderBy("createdAt", "desc")
      .get();

    const requests = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.status(200).send(requests);
  } catch (error) {
    console.error("Error fetching requests:", error);
    res.status(500).send({ error: "Failed to fetch requests" });
  }
});

app.get("/admin/donorHistory", requireApiKey, async (req, res) => {
  try {
    const snapshot = await admin
      .firestore()
      .collection("donorHistory")
      .orderBy("timestamp", "desc")
      .get();

    const history = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.status(200).send(history);
  } catch (error) {
    console.error("Error fetching donor history:", error);
    res.status(500).send({ error: "Failed to fetch donor history" });
  }
});

app.get("/admin/notifications", requireApiKey, async (req, res) => {
  try {
    const snapshot = await admin
      .firestore()
      .collection("notifications")
      .orderBy("timestamp", "desc")
      .get();

    const notifications = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.status(200).send(notifications);
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).send({ error: "Failed to fetch notifications" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));