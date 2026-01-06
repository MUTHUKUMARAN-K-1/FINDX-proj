'use client';

import { useState, useEffect, createContext, useContext } from 'react';
import { 
  onAuthStateChanged, 
  signInWithPopup, 
  GoogleAuthProvider,
  signOut as firebaseSignOut,
  User as FirebaseUser 
} from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { User } from '@/types';

interface AuthContextType {
  user: User | null;
  firebaseUser: FirebaseUser | null;
  loading: boolean;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Mock user for development
const MOCK_USER: User = {
  id: 'user1',
  displayName: 'Rahul Kumar',
  email: 'rahul@cit.edu',
  photoURL: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  phone: '+91 98765 43210',
  notificationRadius: 5,
  heroLevel: 3,
  totalFinds: 23,
  totalReports: 8,
  reputationScore: 95,
  badges: ['early_adopter', 'top_finder', 'helpful'],
  notifications: {
    push: true,
    email: true,
    sms: false,
    categories: ['item', 'pet'],
  },
  organizationId: 'cit',
  role: 'member',
  createdAt: new Date('2024-01-15'),
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if Firebase is configured
    const isFirebaseConfigured = process.env.NEXT_PUBLIC_FIREBASE_API_KEY && 
                                  process.env.NEXT_PUBLIC_FIREBASE_API_KEY !== 'your_firebase_api_key';

    if (isFirebaseConfigured && auth) {
      // Use real Firebase auth
      const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
        if (fbUser) {
          setFirebaseUser(fbUser);
          // Fetch user data from Firestore
          // For now, create a user object from Firebase data
          setUser({
            id: fbUser.uid,
            displayName: fbUser.displayName || 'User',
            email: fbUser.email || '',
            photoURL: fbUser.photoURL || undefined,
            notificationRadius: 5,
            heroLevel: 1,
            totalFinds: 0,
            totalReports: 0,
            reputationScore: 50,
            badges: [],
            notifications: {
              push: true,
              email: true,
              sms: false,
              categories: ['item', 'pet', 'person'],
            },
            role: 'member',
            createdAt: new Date(),
          });
        } else {
          setFirebaseUser(null);
          setUser(null);
        }
        setLoading(false);
      });

      return () => unsubscribe();
    } else {
      // Use mock user for development
      setUser(MOCK_USER);
      setLoading(false);
    }
  }, []);

  const signInWithGoogle = async () => {
    const isFirebaseConfigured = process.env.NEXT_PUBLIC_FIREBASE_API_KEY && 
                                  process.env.NEXT_PUBLIC_FIREBASE_API_KEY !== 'your_firebase_api_key';

    if (isFirebaseConfigured && auth) {
      const provider = new GoogleAuthProvider();
      try {
        await signInWithPopup(auth, provider);
      } catch (error) {
        console.error('Google sign in error:', error);
        throw error;
      }
    } else {
      // Mock sign in
      setUser(MOCK_USER);
    }
  };

  const signOut = async () => {
    const isFirebaseConfigured = process.env.NEXT_PUBLIC_FIREBASE_API_KEY && 
                                  process.env.NEXT_PUBLIC_FIREBASE_API_KEY !== 'your_firebase_api_key';

    if (isFirebaseConfigured && auth) {
      try {
        await firebaseSignOut(auth);
      } catch (error) {
        console.error('Sign out error:', error);
        throw error;
      }
    } else {
      // Mock sign out
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider value={{ user, firebaseUser, loading, signInWithGoogle, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
