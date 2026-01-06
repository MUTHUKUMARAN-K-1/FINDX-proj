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
  limit,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';

export interface Notification {
  id: string;
  type: 'match' | 'claim' | 'message' | 'system' | 'reward';
  title: string;
  body: string;
  itemId?: string;
  matchId?: string;
  read: boolean;
  createdAt: Date;
  userId: string;
}

// Check if Firebase is configured
const isFirebaseConfigured = () => {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  return apiKey && apiKey !== 'your_firebase_api_key' && apiKey.length > 10;
};

// Mock notifications
const MOCK_NOTIFICATIONS: Notification[] = [
  {
    id: 'notif-1',
    type: 'match',
    title: 'Potential Match Found! 🎉',
    body: 'Your lost iPhone 15 Pro might have been found nearby with 87% confidence.',
    itemId: '1',
    matchId: 'match-1',
    read: false,
    createdAt: new Date(Date.now() - 30 * 60 * 1000),
    userId: 'user1',
  },
  {
    id: 'notif-2',
    type: 'claim',
    title: 'New Claim on Your Item',
    body: 'Someone has claimed to be the owner of the wallet you found.',
    itemId: '3',
    read: false,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    userId: 'user1',
  },
  {
    id: 'notif-3',
    type: 'reward',
    title: 'Hero Points Earned! 🏆',
    body: 'You earned +50 points for helping return a lost item. Level up!',
    read: true,
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    userId: 'user1',
  },
  {
    id: 'notif-4',
    type: 'system',
    title: 'Welcome to FINDX!',
    body: 'Start by enabling location to see lost and found items near you.',
    read: true,
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000),
    userId: 'user1',
  },
];

// Convert Firestore doc to Notification
function docToNotification(doc: any): Notification {
  const data = doc.data();
  return {
    id: doc.id,
    type: data.type,
    title: data.title,
    body: data.body,
    itemId: data.itemId,
    matchId: data.matchId,
    read: data.read || false,
    createdAt: data.createdAt?.toDate() || new Date(),
    userId: data.userId,
  };
}

export function useNotifications(userId: string = 'user1') {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);

  const fetchNotifications = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      if (isFirebaseConfigured() && db) {
        const q = query(
          collection(db, 'notifications'),
          where('userId', '==', userId),
          orderBy('createdAt', 'desc'),
          limit(50)
        );

        const snapshot = await getDocs(q);
        const notifs = snapshot.docs.map(docToNotification);
        setNotifications(notifs);
        setUnreadCount(notifs.filter(n => !n.read).length);
      } else {
        await new Promise(resolve => setTimeout(resolve, 200));
        const userNotifs = MOCK_NOTIFICATIONS.filter(n => n.userId === userId);
        setNotifications(userNotifs);
        setUnreadCount(userNotifs.filter(n => !n.read).length);
      }
    } catch (err) {
      console.error('Error fetching notifications:', err);
      setError('Failed to load notifications');
      setNotifications(MOCK_NOTIFICATIONS);
      setUnreadCount(MOCK_NOTIFICATIONS.filter(n => !n.read).length);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  return { 
    notifications, 
    loading, 
    error, 
    unreadCount,
    refresh: fetchNotifications 
  };
}

// Real-time notifications subscription
export function useRealtimeNotifications(userId: string = 'user1') {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!isFirebaseConfigured() || !db) {
      const userNotifs = MOCK_NOTIFICATIONS.filter(n => n.userId === userId);
      setNotifications(userNotifs);
      setUnreadCount(userNotifs.filter(n => !n.read).length);
      setLoading(false);
      return;
    }

    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', userId),
      orderBy('createdAt', 'desc'),
      limit(50)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const notifs = snapshot.docs.map(docToNotification);
      setNotifications(notifs);
      setUnreadCount(notifs.filter(n => !n.read).length);
      setLoading(false);
    }, (err) => {
      console.error('Notification subscription error:', err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [userId]);

  return { notifications, loading, unreadCount };
}

// Mark notification as read
export async function markNotificationRead(notificationId: string): Promise<void> {
  console.log('Marking notification as read:', notificationId);
  
  if (isFirebaseConfigured() && db) {
    try {
      const docRef = doc(db, 'notifications', notificationId);
      await updateDoc(docRef, { read: true });
    } catch (error) {
      console.error('Error marking notification read:', error);
      throw error;
    }
  }
}

// Mark all notifications as read
export async function markAllNotificationsRead(userId: string): Promise<void> {
  console.log('Marking all notifications as read for:', userId);
  
  if (isFirebaseConfigured() && db) {
    try {
      const q = query(
        collection(db, 'notifications'),
        where('userId', '==', userId),
        where('read', '==', false)
      );
      const snapshot = await getDocs(q);
      
      const updates = snapshot.docs.map(d => 
        updateDoc(doc(db, 'notifications', d.id), { read: true })
      );
      await Promise.all(updates);
    } catch (error) {
      console.error('Error marking all notifications read:', error);
      throw error;
    }
  }
}

// Create a notification
export async function createNotification(
  notification: Omit<Notification, 'id' | 'createdAt' | 'read'>
): Promise<string> {
  console.log('Creating notification:', notification);
  
  if (isFirebaseConfigured() && db) {
    try {
      const docRef = await addDoc(collection(db, 'notifications'), {
        ...notification,
        read: false,
        createdAt: serverTimestamp(),
      });
      return docRef.id;
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  } else {
    return `notif-${Date.now()}`;
  }
}
