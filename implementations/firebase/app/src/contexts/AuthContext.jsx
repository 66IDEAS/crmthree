import { createContext, useContext, useEffect, useMemo, useState, useCallback } from 'react';
import { auth } from '../config/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import {
  signInWithEmail,
  signInWithGoogle,
  signOut,
  resolveUserSession,
} from '../services/AuthService';

const AuthContext = createContext({
  user: null,
  userProfile: null,
  role: null,
  loading: true,
  profileLoading: false,
  error: null,
  rejectedReason: null,
  signInEmail: async () => {},
  signInGoogle: async () => {},
  handleSignOut: async () => {},
  hasPermission: () => false,
});

export function useAuth() {
  return useContext(AuthContext);
}

export default function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [userProfile, setUserProfile] = useState(null);
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(true);
  const [profileLoading, setProfileLoading] = useState(false);
  const [error, setError] = useState(null);
  const [rejectedReason, setRejectedReason] = useState(null);

  // Load UserProfile + Role after Firebase Auth resolves
  const loadUserSession = useCallback(async (firebaseUser) => {
    if (!firebaseUser) {
      setUserProfile(null);
      setRole(null);
      setRejectedReason(null);
      setProfileLoading(false);
      return;
    }

    setProfileLoading(true);
    setError(null);
    setRejectedReason(null);
    try {
      const result = await resolveUserSession(firebaseUser);
      setUserProfile(result.profile);
      setRole(result.role);
      setRejectedReason(result.rejected || null);
    } catch (err) {
      setError(err.message || 'Failed to load user profile');
    } finally {
      setProfileLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!auth) {
      setLoading(false);
      return;
    }
    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);
      setLoading(false);
      loadUserSession(firebaseUser);
    });
    return unsubscribe;
  }, [loadUserSession]);

  const signInEmail = useCallback(async (email, password) => {
    setError(null);
    return signInWithEmail(email, password);
  }, []);

  const signInGoogle = useCallback(async () => {
    setError(null);
    return signInWithGoogle();
  }, []);

  const handleSignOut = useCallback(async () => {
    await signOut();
    setUser(null);
    setUserProfile(null);
    setRole(null);
    setRejectedReason(null);
  }, []);

  const hasPermission = useCallback(
    (objectType, action) => {
      if (!role?.permissions) return false;
      // Check object-specific permission first
      const objPerms = role.permissions[objectType];
      if (objPerms && objPerms[action] !== undefined) return objPerms[action];
      // Fallback to wildcard
      const wildcard = role.permissions['*'];
      if (wildcard && wildcard[action] !== undefined) return wildcard[action];
      return false;
    },
    [role]
  );

  const value = useMemo(
    () => ({
      user,
      userProfile,
      role,
      loading,
      profileLoading,
      error,
      rejectedReason,
      signInEmail,
      signInGoogle,
      handleSignOut,
      hasPermission,
    }),
    [user, userProfile, role, loading, profileLoading, error, rejectedReason, signInEmail, signInGoogle, handleSignOut, hasPermission]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
