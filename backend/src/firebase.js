const admin = require('firebase-admin');
const path = require('path');
require('dotenv').config();

const serviceAccountPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
});

const db = admin.firestore();
const messaging = admin.messaging();
const auth = admin.auth();

module.exports = { admin, db, messaging, auth };
