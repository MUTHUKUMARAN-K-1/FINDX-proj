'use client';

import { useState, useEffect, useCallback } from 'react';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit,
  addDoc,
  getDoc,
  getDocs,
  doc,
  onSnapshot,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Item, ItemType, ItemStatus } from '@/types';

// Check if Firebase is configured
const isFirebaseConfigured = () => {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  return apiKey && apiKey !== 'your_firebase_api_key' && apiKey.length > 10;
};

// Mock data for development when Firebase isn't configured
const MOCK_ITEMS: Item[] = [
  {
    id: '1',
    type: 'lost',
    category: 'item',
    status: 'active',
    title: 'iPhone 15 Pro Max',
    description: 'Space Black, 256GB. Has a small crack on the top right corner. Blue leather case with card slots.',
    aiTags: ['iphone', 'apple', 'phone', 'space black', 'cracked screen'],
    images: ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'CIT Cafeteria',
    radius: 5,
    reportedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    reportedBy: 'user1',
    reward: 5000,
  },
  {
    id: '2',
    type: 'lost',
    category: 'pet',
    status: 'active',
    title: 'Golden Retriever - Max',
    description: 'Male, 3 years old. Cream colored with a red collar. Very friendly.',
    aiTags: ['dog', 'golden retriever', 'pet', 'cream', 'red collar'],
    images: ['https://images.unsplash.com/photo-1552053831-71594a27632d?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'HSR Layout Park',
    radius: 10,
    reportedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
    reportedBy: 'user2',
    reward: 10000,
  },
  {
    id: '3',
    type: 'found',
    category: 'item',
    status: 'active',
    title: 'Blue Backpack with Books',
    description: 'Found near the library entrance. Contains textbooks and a water bottle.',
    aiTags: ['backpack', 'blue', 'books', 'library', 'water bottle'],
    images: ['https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'CIT Library',
    radius: 1,
    reportedAt: new Date(Date.now() - 30 * 60 * 1000),
    reportedBy: 'user3',
  },
  {
    id: '4',
    type: 'found',
    category: 'item',
    status: 'matched',
    title: 'Car Keys with Honda Logo',
    description: 'Found in parking lot B. Honda key fob with a small teddy bear keychain.',
    aiTags: ['keys', 'car keys', 'honda', 'keychain', 'teddy bear'],
    images: ['https://images.unsplash.com/photo-1514316454349-750a7fd3da3a?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'Parking Lot B',
    radius: 1,
    reportedAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
    reportedBy: 'user4',
  },
  {
    id: '5',
    type: 'lost',
    category: 'item',
    status: 'active',
    title: 'MacBook Pro 14"',
    description: 'Space Gray, M2 Pro chip. Has stickers on the lid - a cat and a coffee cup.',
    aiTags: ['macbook', 'apple', 'laptop', 'space gray', 'stickers'],
    images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca4?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'CIT Computer Lab',
    radius: 2,
    reportedAt: new Date(Date.now() - 4 * 60 * 60 * 1000),
    reportedBy: 'user1',
    reward: 15000,
  },
];

// Convert Firestore document to Item
function docToItem(doc: any): Item {
  const data = doc.data();
  return {
    id: doc.id,
    type: data.type,
    category: data.category,
    status: data.status,
    title: data.title,
    description: data.description,
    aiTags: data.aiTags || [],
    images: data.images || [],
    location: data.location ? { lat: data.location.latitude, lng: data.location.longitude } : null,
    locationName: data.locationName || '',
    radius: data.radius || 5,
    reportedAt: data.reportedAt?.toDate() || new Date(),
    reportedBy: data.reportedBy,
    reward: data.reward,
    verificationQuestions: data.verificationQuestions,
  };
}

export function useItems(type?: ItemType) {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      if (isFirebaseConfigured() && db) {
        // Use Firebase
        let q = query(
          collection(db, 'items'),
          where('status', '==', 'active'),
          orderBy('reportedAt', 'desc'),
          limit(50)
        );

        if (type) {
          q = query(
            collection(db, 'items'),
            where('status', '==', 'active'),
            where('type', '==', type),
            orderBy('reportedAt', 'desc'),
            limit(50)
          );
        }

        const snapshot = await getDocs(q);
        const fetchedItems = snapshot.docs.map(docToItem);
        setItems(fetchedItems);
      } else {
        // Use mock data
        await new Promise(resolve => setTimeout(resolve, 300));
        let filteredItems = MOCK_ITEMS.filter(item => item.status === 'active');
        if (type) {
          filteredItems = filteredItems.filter(item => item.type === type);
        }
        setItems(filteredItems);
      }
    } catch (err) {
      console.error('Error fetching items:', err);
      setError('Failed to load items');
      // Fallback to mock data on error
      setItems(MOCK_ITEMS.filter(item => item.status === 'active'));
    } finally {
      setLoading(false);
    }
  }, [type]);

  useEffect(() => {
    fetchItems();
  }, [fetchItems]);

  const refresh = () => {
    fetchItems();
  };

  return { items, loading, error, refresh };
}

export function useItem(itemId: string) {
  const [item, setItem] = useState<Item | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchItem = async () => {
      setLoading(true);
      setError(null);
      
      try {
        if (isFirebaseConfigured() && db) {
          const docRef = doc(db, 'items', itemId);
          const docSnap = await getDoc(docRef);
          
          if (docSnap.exists()) {
            setItem(docToItem(docSnap));
          } else {
            setItem(null);
          }
        } else {
          await new Promise(resolve => setTimeout(resolve, 200));
          const foundItem = MOCK_ITEMS.find(i => i.id === itemId) || null;
          setItem(foundItem);
        }
      } catch (err) {
        console.error('Error fetching item:', err);
        setError('Failed to load item');
        const foundItem = MOCK_ITEMS.find(i => i.id === itemId) || null;
        setItem(foundItem);
      } finally {
        setLoading(false);
      }
    };

    if (itemId) {
      fetchItem();
    }
  }, [itemId]);

  return { item, loading, error };
}

export function useUserItems(userId: string) {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchUserItems = async () => {
      setLoading(true);
      setError(null);
      
      try {
        if (isFirebaseConfigured() && db) {
          const q = query(
            collection(db, 'items'),
            where('reportedBy', '==', userId),
            orderBy('reportedAt', 'desc')
          );
          const snapshot = await getDocs(q);
          setItems(snapshot.docs.map(docToItem));
        } else {
          await new Promise(resolve => setTimeout(resolve, 200));
          const userItems = MOCK_ITEMS.filter(i => i.reportedBy === userId);
          setItems(userItems);
        }
      } catch (err) {
        console.error('Error fetching user items:', err);
        setError('Failed to load your items');
        setItems(MOCK_ITEMS.filter(i => i.reportedBy === userId));
      } finally {
        setLoading(false);
      }
    };

    if (userId) {
      fetchUserItems();
    }
  }, [userId]);

  return { items, loading, error };
}

// Real-time subscription to items
export function useRealtimeItems(type?: ItemType) {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isFirebaseConfigured() || !db) {
      // Use mock data
      setItems(MOCK_ITEMS.filter(item => 
        item.status === 'active' && (!type || item.type === type)
      ));
      setLoading(false);
      return;
    }

    let q = query(
      collection(db, 'items'),
      where('status', '==', 'active'),
      orderBy('reportedAt', 'desc'),
      limit(50)
    );

    if (type) {
      q = query(
        collection(db, 'items'),
        where('status', '==', 'active'),
        where('type', '==', type),
        orderBy('reportedAt', 'desc'),
        limit(50)
      );
    }

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedItems = snapshot.docs.map(docToItem);
      setItems(fetchedItems);
      setLoading(false);
    }, (err) => {
      console.error('Real-time items error:', err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [type]);

  return { items, loading };
}

// Add a new item
export async function addItem(item: Omit<Item, 'id' | 'reportedAt'>): Promise<string> {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  const isConfigured = apiKey && apiKey !== 'your_firebase_api_key' && apiKey.length > 10;
  
  console.log('=== addItem Debug ===');
  console.log('Firebase configured:', isConfigured);
  console.log('API Key exists:', !!apiKey);
  console.log('API Key length:', apiKey?.length);
  console.log('db exists:', !!db);
  console.log('Item to save:', item);
  
  if (isConfigured && db) {
    try {
      console.log('Attempting to save to Firebase...');
      const docRef = await addDoc(collection(db, 'items'), {
        ...item,
        reportedAt: serverTimestamp(),
        status: 'active',
      });
      console.log('SUCCESS! Document saved with ID:', docRef.id);
      return docRef.id;
    } catch (error) {
      console.error('FIREBASE ERROR:', error);
      throw error;
    }
  } else {
    // Mock add
    console.log('Using MOCK mode - data NOT saved to Firebase');
    const mockId = `item-${Date.now()}`;
    console.log('Mock ID:', mockId);
    return mockId;
  }
}

// Update item status
export async function updateItemStatus(itemId: string, status: ItemStatus): Promise<void> {
  if (isFirebaseConfigured() && db) {
    const docRef = doc(db, 'items', itemId);
    await updateDoc(docRef, { status, updatedAt: serverTimestamp() });
  } else {
    console.log('Mock updating item status:', itemId, status);
  }
}
