// The one place the Admin SDK is initialized. Services import from here.
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

if (getApps().length === 0) initializeApp();

export const db = () => getFirestore();
export const auth = () => getAuth();
export const storage = () => getStorage();
