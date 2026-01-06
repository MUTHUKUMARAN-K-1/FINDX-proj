// Utility functions for FINDX

/**
 * Format a date to relative time (e.g., "2 hours ago")
 */
export function formatDistanceToNow(date: Date | string): string {
  const now = new Date();
  const past = new Date(date);
  const diffMs = now.getTime() - past.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} min ago`;
  if (diffHours < 24) return `${diffHours} hr ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
  
  return past.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}

/**
 * Calculate distance between two coordinates in km
 */
export function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Format distance for display
 */
export function formatDistance(km: number): string {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1)} km`;
}

/**
 * Convert file to base64
 */
export function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = (error) => reject(error);
  });
}

/**
 * Compress image before upload
 */
export async function compressImage(
  file: File,
  maxWidth = 1200,
  quality = 0.8
): Promise<Blob> {
  return new Promise((resolve) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d')!;
    const img = new window.Image();
    
    img.onload = () => {
      const ratio = Math.min(maxWidth / img.width, maxWidth / img.height);
      canvas.width = img.width * ratio;
      canvas.height = img.height * ratio;
      
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      
      canvas.toBlob((blob) => resolve(blob!), 'image/jpeg', quality);
    };
    
    img.src = URL.createObjectURL(file);
  });
}

/**
 * Generate a unique ID
 */
export function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

/**
 * Truncate text with ellipsis
 */
export function truncate(text: string, length: number): string {
  if (text.length <= length) return text;
  return text.slice(0, length) + '...';
}

/**
 * Debounce function
 */
export function debounce<T extends (...args: unknown[]) => unknown>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

/**
 * Get hero level from finds count
 */
export function getHeroLevel(finds: number): {
  level: number;
  name: string;
  badge: string;
  progress: number;
  nextLevelAt: number;
} {
  const levels = [
    { level: 1, name: 'Scout', minFinds: 0, badge: '🥉' },
    { level: 2, name: 'Finder', minFinds: 11, badge: '🥈' },
    { level: 3, name: 'Guardian', minFinds: 51, badge: '🥇' },
    { level: 4, name: 'Legend', minFinds: 101, badge: '💎' },
    { level: 5, name: 'Champion', minFinds: 201, badge: '🏆' },
  ];

  let currentLevel = levels[0];
  let nextLevelAt = levels[1].minFinds;

  for (let i = levels.length - 1; i >= 0; i--) {
    if (finds >= levels[i].minFinds) {
      currentLevel = levels[i];
      nextLevelAt = levels[i + 1]?.minFinds || levels[i].minFinds;
      break;
    }
  }

  const prevLevelFinds = currentLevel.minFinds;
  const progress = currentLevel.level === 5 
    ? 100 
    : ((finds - prevLevelFinds) / (nextLevelAt - prevLevelFinds)) * 100;

  return {
    ...currentLevel,
    progress: Math.min(100, Math.max(0, progress)),
    nextLevelAt,
  };
}

/**
 * Validate phone number (Indian format)
 */
export function isValidPhone(phone: string): boolean {
  const pattern = /^[6-9]\d{9}$/;
  return pattern.test(phone.replace(/\D/g, ''));
}

/**
 * Format phone number for display
 */
export function formatPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 10) {
    return `+91 ${digits.slice(0, 5)} ${digits.slice(5)}`;
  }
  return phone;
}

/**
 * Classname utility (like clsx/cn)
 */
export function cn(...classes: (string | boolean | undefined | null)[]): string {
  return classes.filter(Boolean).join(' ');
}
