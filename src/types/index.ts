// Core types for FINDX application

export type ItemType = 'lost' | 'found';
export type ItemCategory = 'item' | 'pet' | 'person';
export type ItemStatus = 'active' | 'matched' | 'recovered' | 'closed';

export interface Location {
  lat: number;
  lng: number;
}

export interface Item {
  id: string;
  type: ItemType;
  category: ItemCategory;
  status: ItemStatus;
  
  // Content
  title: string;
  description: string;
  aiTags: string[];
  
  // Media
  images: string[];
  
  // Location
  location: Location | null;
  locationName: string;
  radius: number; // in km
  
  // Metadata
  reportedAt: Date;
  reportedBy: string;
  reward?: number;
  
  // Matching & Claims
  matches?: string[];
  claims?: Claim[];
  
  // Verification
  verificationQuestions?: VerificationQuestion[];
}

export interface VerificationQuestion {
  question: string;
  answer: string;
}

export interface Claim {
  id: string;
  claimantId: string;
  claimantName: string;
  message: string;
  createdAt: Date;
  status: 'pending' | 'approved' | 'rejected';
  verificationAnswers?: string[];
}

export interface User {
  id: string;
  displayName: string;
  email: string;
  phone?: string;
  photoURL?: string;
  
  // Location
  location?: Location;
  notificationRadius: number; // km
  
  // Gamification
  heroLevel: number;
  totalFinds: number;
  totalReports: number;
  reputationScore: number;
  badges: string[];
  
  // Notification settings
  notifications: {
    push: boolean;
    email: boolean;
    sms: boolean;
    categories: ItemCategory[];
  };
  
  // Organization
  organizationId?: string;
  role?: 'member' | 'admin';
  
  createdAt: Date;
}

export interface Match {
  id: string;
  lostItemId: string;
  foundItemId: string;
  confidence: number; // 0-100
  matchReasons: string[];
  status: 'pending' | 'confirmed' | 'rejected';
  createdAt: Date;
}

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

export interface Organization {
  id: string;
  name: string;
  type: 'college' | 'hospital' | 'office' | 'mall' | 'other';
  logo?: string;
  location: Location;
  admins: string[];
  members: string[];
  settings: {
    autoNotify: boolean;
    requireApproval: boolean;
  };
  stats: {
    totalReports: number;
    totalRecovered: number;
    recoveryRate: number;
    avgRecoveryTime: number; // in hours
  };
  createdAt: Date;
}

// Hero levels
export const HERO_LEVELS = [
  { level: 1, name: 'Scout', minFinds: 0, badge: '🥉', color: '#CD7F32' },
  { level: 2, name: 'Finder', minFinds: 11, badge: '🥈', color: '#C0C0C0' },
  { level: 3, name: 'Guardian', minFinds: 51, badge: '🥇', color: '#FFD700' },
  { level: 4, name: 'Legend', minFinds: 101, badge: '💎', color: '#B9F2FF' },
  { level: 5, name: 'Champion', minFinds: 201, badge: '🏆', color: '#E5E4E2' },
] as const;

// Category icons
export const CATEGORY_ICONS: Record<ItemCategory, string> = {
  item: '📦',
  pet: '🐾',
  person: '👤',
};

// Status colors
export const STATUS_COLORS: Record<ItemStatus, string> = {
  active: 'text-yellow-400',
  matched: 'text-purple-400',
  recovered: 'text-green-400',
  closed: 'text-slate-400',
};

// AI-generated report from Gemini
export interface AIGeneratedReport {
  title: string;
  description: string;
  category: ItemCategory;
  aiTags: string[];
  brand?: string;
  color?: string;
  identifyingMarks?: string[];
  suggestedQuestions?: string[];
}
