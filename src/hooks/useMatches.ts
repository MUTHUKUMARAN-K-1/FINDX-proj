'use client';

import { useState, useEffect, useCallback } from 'react';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  addDoc,
  getDocs,
  doc,
  updateDoc,
  onSnapshot,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Match } from '@/types';

// Check if Firebase is configured
const isFirebaseConfigured = () => {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  return apiKey && apiKey !== 'your_firebase_api_key' && apiKey.length > 10;
};

// Mock matches data
const MOCK_MATCHES: Match[] = [
  {
    id: 'match-1',
    lostItemId: '1',
    foundItemId: '3',
    confidence: 87,
    matchReasons: ['Same category', 'Similar location (0.5km)', 'Matching AI tags'],
    status: 'pending',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
  },
  {
    id: 'match-2',
    lostItemId: '5',
    foundItemId: '4',
    confidence: 72,
    matchReasons: ['Similar description', 'Same area (2.1km)'],
    status: 'pending',
    createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
  },
];

// Convert Firestore document to Match
function docToMatch(doc: any): Match {
  const data = doc.data();
  return {
    id: doc.id,
    lostItemId: data.lostItemId,
    foundItemId: data.foundItemId,
    confidence: data.confidence,
    matchReasons: data.matchReasons || [],
    status: data.status,
    createdAt: data.createdAt?.toDate() || new Date(),
  };
}

// Get all matches
export function useMatches(status?: Match['status']) {
  const [matches, setMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMatches = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      if (isFirebaseConfigured() && db) {
        let q = query(
          collection(db, 'matches'),
          orderBy('createdAt', 'desc')
        );

        if (status) {
          q = query(
            collection(db, 'matches'),
            where('status', '==', status),
            orderBy('createdAt', 'desc')
          );
        }

        const snapshot = await getDocs(q);
        setMatches(snapshot.docs.map(docToMatch));
      } else {
        await new Promise(resolve => setTimeout(resolve, 300));
        let filteredMatches = [...MOCK_MATCHES];
        if (status) {
          filteredMatches = filteredMatches.filter(m => m.status === status);
        }
        setMatches(filteredMatches);
      }
    } catch (err) {
      console.error('Error fetching matches:', err);
      setError('Failed to load matches');
      setMatches(MOCK_MATCHES);
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => {
    fetchMatches();
  }, [fetchMatches]);

  return { matches, loading, error, refresh: fetchMatches };
}

// Get matches for a specific user's items
export function useUserMatches(userId: string) {
  const [matches, setMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isFirebaseConfigured() || !db) {
      setMatches(MOCK_MATCHES);
      setLoading(false);
      return;
    }

    // Real-time subscription
    const q = query(
      collection(db, 'matches'),
      orderBy('createdAt', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const allMatches = snapshot.docs.map(docToMatch);
      // Filter matches where user owns either lost or found item
      // In production, you'd do this query server-side
      setMatches(allMatches);
      setLoading(false);
    }, (err) => {
      console.error('Match subscription error:', err);
      setMatches(MOCK_MATCHES);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [userId]);

  return { matches, loading };
}

// Create a new match
export async function createMatch(match: Omit<Match, 'id' | 'createdAt'>): Promise<string> {
  console.log('Creating match:', match);
  
  if (isFirebaseConfigured() && db) {
    try {
      const docRef = await addDoc(collection(db, 'matches'), {
        ...match,
        createdAt: serverTimestamp(),
      });
      console.log('Match created with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('Error creating match:', error);
      throw error;
    }
  } else {
    const mockId = `match-${Date.now()}`;
    console.log('Mock match created:', mockId);
    return mockId;
  }
}

// Update match status
export async function updateMatchStatus(
  matchId: string, 
  status: Match['status']
): Promise<void> {
  console.log('Updating match status:', matchId, status);
  
  if (isFirebaseConfigured() && db) {
    try {
      const docRef = doc(db, 'matches', matchId);
      await updateDoc(docRef, { 
        status, 
        updatedAt: serverTimestamp() 
      });
      console.log('Match status updated');
    } catch (error) {
      console.error('Error updating match:', error);
      throw error;
    }
  } else {
    console.log('Mock match status update:', matchId, status);
  }
}

// Confirm a match (both parties agree)
export async function confirmMatch(matchId: string): Promise<void> {
  await updateMatchStatus(matchId, 'confirmed');
}

// Reject a match
export async function rejectMatch(matchId: string): Promise<void> {
  await updateMatchStatus(matchId, 'rejected');
}
