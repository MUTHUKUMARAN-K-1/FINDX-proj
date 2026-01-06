import { 
  collection, 
  doc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  getDoc, 
  getDocs, 
  query, 
  where, 
  orderBy, 
  limit,
  onSnapshot,
  serverTimestamp,
  GeoPoint,
  Timestamp,
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from './firebase';
import { Item, User, Match, Notification, ItemType, ItemStatus } from '@/types';

// ============================================
// ITEMS
// ============================================

export async function createItem(
  item: Omit<Item, 'id' | 'reportedAt'>,
  userId: string
): Promise<string> {
  const itemData = {
    ...item,
    reportedBy: userId,
    reportedAt: serverTimestamp(),
    status: 'active' as ItemStatus,
    location: item.location 
      ? new GeoPoint(item.location.lat, item.location.lng) 
      : null,
  };

  const docRef = await addDoc(collection(db, 'items'), itemData);
  return docRef.id;
}

export async function getItem(itemId: string): Promise<Item | null> {
  const docRef = doc(db, 'items', itemId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) return null;
  
  const data = docSnap.data();
  return {
    id: docSnap.id,
    ...data,
    reportedAt: data.reportedAt?.toDate() || new Date(),
    location: data.location 
      ? { lat: data.location.latitude, lng: data.location.longitude }
      : null,
  } as Item;
}

export async function getRecentItems(
  type?: ItemType,
  limitCount: number = 20
): Promise<Item[]> {
  let q = query(
    collection(db, 'items'),
    where('status', '==', 'active'),
    orderBy('reportedAt', 'desc'),
    limit(limitCount)
  );

  if (type) {
    q = query(
      collection(db, 'items'),
      where('status', '==', 'active'),
      where('type', '==', type),
      orderBy('reportedAt', 'desc'),
      limit(limitCount)
    );
  }

  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    reportedAt: doc.data().reportedAt?.toDate() || new Date(),
    location: doc.data().location 
      ? { lat: doc.data().location.latitude, lng: doc.data().location.longitude }
      : null,
  })) as Item[];
}

export async function getUserItems(userId: string): Promise<Item[]> {
  const q = query(
    collection(db, 'items'),
    where('reportedBy', '==', userId),
    orderBy('reportedAt', 'desc')
  );

  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    reportedAt: doc.data().reportedAt?.toDate() || new Date(),
    location: doc.data().location 
      ? { lat: doc.data().location.latitude, lng: doc.data().location.longitude }
      : null,
  })) as Item[];
}

export async function updateItemStatus(
  itemId: string, 
  status: ItemStatus
): Promise<void> {
  const docRef = doc(db, 'items', itemId);
  await updateDoc(docRef, { status, updatedAt: serverTimestamp() });
}

export function subscribeToNearbyItems(
  callback: (items: Item[]) => void,
  limitCount: number = 20
): () => void {
  const q = query(
    collection(db, 'items'),
    where('status', '==', 'active'),
    orderBy('reportedAt', 'desc'),
    limit(limitCount)
  );

  return onSnapshot(q, (snapshot) => {
    const items = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      reportedAt: doc.data().reportedAt?.toDate() || new Date(),
      location: doc.data().location 
        ? { lat: doc.data().location.latitude, lng: doc.data().location.longitude }
        : null,
    })) as Item[];
    callback(items);
  });
}

// ============================================
// IMAGE UPLOAD
// ============================================

export async function uploadImage(
  file: File | Blob,
  path: string
): Promise<string> {
  const storageRef = ref(storage, path);
  await uploadBytes(storageRef, file);
  return getDownloadURL(storageRef);
}

export async function uploadItemImage(
  file: File | Blob,
  userId: string
): Promise<string> {
  const fileName = `items/${userId}/${Date.now()}.jpg`;
  return uploadImage(file, fileName);
}

// ============================================
// MATCHES
// ============================================

export async function createMatch(
  lostItemId: string,
  foundItemId: string,
  confidence: number
): Promise<string> {
  const matchData = {
    lostItemId,
    foundItemId,
    confidence,
    status: 'pending',
    createdAt: serverTimestamp(),
  };

  const docRef = await addDoc(collection(db, 'matches'), matchData);
  return docRef.id;
}

export async function getMatchesForItem(itemId: string): Promise<Match[]> {
  const q = query(
    collection(db, 'matches'),
    where('lostItemId', '==', itemId)
  );

  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate() || new Date(),
  })) as Match[];
}

export async function updateMatchStatus(
  matchId: string,
  status: 'confirmed' | 'rejected'
): Promise<void> {
  const docRef = doc(db, 'matches', matchId);
  await updateDoc(docRef, { status, updatedAt: serverTimestamp() });
}

// ============================================
// NOTIFICATIONS
// ============================================

export async function createNotification(
  userId: string,
  type: Notification['type'],
  title: string,
  message: string,
  itemId?: string,
  matchId?: string
): Promise<string> {
  const notificationData = {
    userId,
    type,
    title,
    message,
    read: false,
    itemId: itemId || null,
    matchId: matchId || null,
    createdAt: serverTimestamp(),
  };

  const docRef = await addDoc(collection(db, 'notifications'), notificationData);
  return docRef.id;
}

export async function getUserNotifications(userId: string): Promise<Notification[]> {
  const q = query(
    collection(db, 'notifications'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    limit(50)
  );

  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate() || new Date(),
  })) as Notification[];
}

export async function markNotificationAsRead(notificationId: string): Promise<void> {
  const docRef = doc(db, 'notifications', notificationId);
  await updateDoc(docRef, { read: true });
}

export async function markAllNotificationsAsRead(userId: string): Promise<void> {
  const q = query(
    collection(db, 'notifications'),
    where('userId', '==', userId),
    where('read', '==', false)
  );

  const snapshot = await getDocs(q);
  const updates = snapshot.docs.map(doc => 
    updateDoc(doc.ref, { read: true })
  );
  
  await Promise.all(updates);
}

export function subscribeToNotifications(
  userId: string,
  callback: (notifications: Notification[]) => void
): () => void {
  const q = query(
    collection(db, 'notifications'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    limit(50)
  );

  return onSnapshot(q, (snapshot) => {
    const notifications = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    })) as Notification[];
    callback(notifications);
  });
}

// ============================================
// USERS
// ============================================

export async function createUser(userId: string, userData: Partial<User>): Promise<void> {
  const docRef = doc(db, 'users', userId);
  await updateDoc(docRef, {
    ...userData,
    totalFinds: 0,
    totalReports: 0,
    reputationScore: 50,
    badges: [],
    createdAt: serverTimestamp(),
  });
}

export async function getUser(userId: string): Promise<User | null> {
  const docRef = doc(db, 'users', userId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) return null;
  
  return {
    id: docSnap.id,
    ...docSnap.data(),
  } as User;
}

export async function updateUserStats(
  userId: string,
  field: 'totalFinds' | 'totalReports',
  increment: number = 1
): Promise<void> {
  const docRef = doc(db, 'users', userId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) return;
  
  const currentValue = docSnap.data()[field] || 0;
  await updateDoc(docRef, { 
    [field]: currentValue + increment,
    updatedAt: serverTimestamp(),
  });
}

export async function awardBadge(userId: string, badge: string): Promise<void> {
  const docRef = doc(db, 'users', userId);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) return;
  
  const badges = docSnap.data().badges || [];
  if (!badges.includes(badge)) {
    await updateDoc(docRef, { 
      badges: [...badges, badge],
      updatedAt: serverTimestamp(),
    });
  }
}
