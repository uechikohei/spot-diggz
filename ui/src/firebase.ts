import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const isTest = import.meta.env.MODE === 'test';

const firebaseConfig = isTest
  ? {
      apiKey: 'test-api-key',
      authDomain: 'localhost',
      projectId: 'demo-test',
    }
  : {
      apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
      authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    };

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
