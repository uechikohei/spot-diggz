import { User } from 'firebase/auth';
import { createContext } from 'react';

export type AuthContextValue = {
  user: User | null;
  idToken: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
};

export const AuthContext = createContext<AuthContextValue>({
  user: null,
  idToken: null,
  loading: true,
  login: async () => {},
  logout: async () => {},
});
