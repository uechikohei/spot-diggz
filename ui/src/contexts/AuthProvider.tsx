import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  sendEmailVerification,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from 'firebase/auth';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  doc,
  getDoc,
  getFirestore,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { auth } from '../firebase';
import { AuthContext } from './auth-context';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState(auth.currentUser);
  const [idToken, setIdToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // users/{uid} を存在しなければ作成（createdAtのみセット、updatedAtはnull）
  const ensureUserDoc = useCallback(async (uid: string, email: string | null) => {
    try {
      if (!email) {
        throw new Error('メールアドレスが取得できませんでした。');
      }
      const db = getFirestore();
      const docRef = doc(db, 'users', uid);
      const snap = await getDoc(docRef);
      if (!snap.exists()) {
        await setDoc(
          docRef,
          {
            email,
            createdAt: serverTimestamp(),
            updatedAt: null, // 初回はnull、更新時に上書きする想定
          },
          { merge: true },
        );
      } else {
        // 既存ドキュメントでもemailが空なら補完する
        const current = snap.data();
        if (!current?.email) {
          await setDoc(
            docRef,
            { email, updatedAt: serverTimestamp() },
            { merge: true },
          );
        }
      }

      // 書き込み後に存在を確認し、なければエラー
      const confirm = await getDoc(docRef);
      if (!confirm.exists()) {
        throw new Error('Firestoreにユーザードキュメントを作成できませんでした。');
      }
    } catch (err) {
      console.error('ensureUserDoc failed', err);
      throw err instanceof Error
        ? err
        : new Error('ユーザープロファイルの作成に失敗しました。');
    }
  }, []);

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

  const loginWithGoogle = useCallback(async () => {
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });
    const credential = await signInWithPopup(auth, provider);
    const user = credential.user;
    const token = await user.getIdToken();
    setIdToken(token ?? null);

    await ensureUserDoc(user.uid, user.email);

    // 初回ログイン時のFirestore作成は後続のサーバーサイド処理や別タイミングで実施する想定
  }, [ensureUserDoc]);

  const loginWithEmail = useCallback(async (email: string, password: string) => {
    const credential = await signInWithEmailAndPassword(auth, email, password);
    if (!credential.user.emailVerified) {
      await sendEmailVerification(credential.user);
      setIdToken(null);
      throw new Error('メールアドレスが未認証です。受信トレイの認証メールを確認してください。');
    }
    await ensureUserDoc(credential.user.uid, credential.user.email);
    const token = await credential.user.getIdToken();
    setIdToken(token ?? null);
  }, [ensureUserDoc]);

  const signupWithEmail = useCallback(async (email: string, password: string) => {
    const credential = await createUserWithEmailAndPassword(auth, email, password);
    const user = credential.user;
    await sendEmailVerification(user);
    // 認証完了までは保護するため、トークンはクリアしておく
    setIdToken(null);

    await ensureUserDoc(user.uid, email);
  }, [ensureUserDoc]);

  const logout = useCallback(async () => {
    await signOut(auth);
    setIdToken(null);
  }, []);

  const resendVerification = useCallback(async () => {
    if (auth.currentUser && !auth.currentUser.emailVerified) {
      await sendEmailVerification(auth.currentUser);
    } else {
      throw new Error('再送できる未認証ユーザーが見つかりません。');
    }
  }, []);

  const value = useMemo(
    () => ({
      user,
      idToken,
      loading,
      loginWithGoogle,
      loginWithEmail,
      signupWithEmail,
      resendVerification,
      logout,
    }),
    [user, idToken, loading, loginWithGoogle, loginWithEmail, signupWithEmail, resendVerification, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
