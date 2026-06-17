/**
 * Firebase Admin initialization. Admin SDK bypasses Firestore/Storage security rules,
 * which is why all writes that decide patient-facing status go through functions, not
 * the client (SPEC §2.2, §4).
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const storage = getStorage();
