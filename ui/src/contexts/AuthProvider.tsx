import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { useEffect, useMemo, useState } from 'react';
import { auth } from '../firebase';
import { AuthContext } from './auth-context';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState(auth.currentUser);
  const [idToken, setIdToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (nextUser) => {
      setUser(nextUser);
      if (nextUser) {
        const token = await nextUser.getIdToken();
        setIdToken(token);
      } else {
        setIdToken(null);
      }
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const login = async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email, password);
    const token = await auth.currentUser?.getIdToken();
    setIdToken(token ?? null);
  };

  const logout = async () => {
    await signOut(auth);
    setIdToken(null);
  };

  const value = useMemo(
    () => ({
      user,
      idToken,
      loading,
      login,
      logout,
    }),
    [user, idToken, loading],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
