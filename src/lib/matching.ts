import { Item } from '@/types';
import { calculateMatchConfidence } from './gemini';

interface MatchResult {
  item: Item;
  confidence: number;
  matchReasons: string[];
}

// Calculate distance between two coordinates in km
function calculateDistance(
  lat1: number, 
  lng1: number, 
  lat2: number, 
  lng2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Calculate text similarity using Jaccard index
function calculateTextSimilarity(text1: string, text2: string): number {
  const words1 = text1.toLowerCase().split(/\s+/).filter(w => w.length > 2);
  const words2 = text2.toLowerCase().split(/\s+/).filter(w => w.length > 2);
  
  const set1 = new Set(words1);
  const set2 = new Set(words2);
  
  const intersection = words1.filter(x => set2.has(x));
  const union = Array.from(new Set([...words1, ...words2]));
  
  if (union.length === 0) return 0;
  return intersection.length / union.length;
}

// Calculate tag overlap
function calculateTagOverlap(tags1: string[], tags2: string[]): number {
  if (tags1.length === 0 || tags2.length === 0) return 0;
  
  const arr1 = tags1.map(t => t.toLowerCase());
  const arr2 = tags2.map(t => t.toLowerCase());
  const set2 = new Set(arr2);
  
  const intersection = arr1.filter(x => set2.has(x));
  return intersection.length / Math.min(arr1.length, arr2.length);
}

// Main matching function
export async function findMatches(
  targetItem: Item,
  candidateItems: Item[],
  useAI: boolean = false
): Promise<MatchResult[]> {
  const results: MatchResult[] = [];
  
  // Filter to opposite type (lost looks for found, found looks for lost)
  const oppositeType = targetItem.type === 'lost' ? 'found' : 'lost';
  const candidates = candidateItems.filter(item => 
    item.type === oppositeType && 
    item.category === targetItem.category &&
    item.status === 'active'
  );

  for (const candidate of candidates) {
    const matchReasons: string[] = [];
    let totalScore = 0;
    let weights = 0;

    // 1. Category match (already filtered, but double-check)
    if (candidate.category === targetItem.category) {
      matchReasons.push('Same category');
    }

    // 2. Location proximity (weight: 25)
    if (targetItem.location && candidate.location) {
      const distance = calculateDistance(
        targetItem.location.lat, 
        targetItem.location.lng,
        candidate.location.lat,
        candidate.location.lng
      );
      
      // Score based on distance: <1km = 1.0, <5km = 0.7, <10km = 0.4, <20km = 0.2
      let locationScore = 0;
      if (distance < 1) {
        locationScore = 1.0;
        matchReasons.push(`Very close (${distance.toFixed(1)}km)`);
      } else if (distance < 5) {
        locationScore = 0.7;
        matchReasons.push(`Nearby (${distance.toFixed(1)}km)`);
      } else if (distance < 10) {
        locationScore = 0.4;
        matchReasons.push(`Same area (${distance.toFixed(1)}km)`);
      } else if (distance < 20) {
        locationScore = 0.2;
      }
      
      totalScore += locationScore * 25;
      weights += 25;
    }

    // 3. Title similarity (weight: 20)
    const titleSimilarity = calculateTextSimilarity(
      targetItem.title, 
      candidate.title
    );
    if (titleSimilarity > 0.3) {
      matchReasons.push('Similar title');
    }
    totalScore += titleSimilarity * 20;
    weights += 20;

    // 4. Description similarity (weight: 15)
    const descSimilarity = calculateTextSimilarity(
      targetItem.description, 
      candidate.description
    );
    if (descSimilarity > 0.3) {
      matchReasons.push('Similar description');
    }
    totalScore += descSimilarity * 15;
    weights += 15;

    // 5. AI Tag overlap (weight: 30)
    const tagOverlap = calculateTagOverlap(
      targetItem.aiTags, 
      candidate.aiTags
    );
    if (tagOverlap > 0.3) {
      matchReasons.push('Matching AI tags');
    }
    totalScore += tagOverlap * 30;
    weights += 30;

    // 6. Time proximity (weight: 10)
    // Items reported close in time are more likely to be matches
    const timeDiff = Math.abs(
      new Date(targetItem.reportedAt).getTime() - 
      new Date(candidate.reportedAt).getTime()
    );
    const hoursDiff = timeDiff / (1000 * 60 * 60);
    let timeScore = 0;
    if (hoursDiff < 24) {
      timeScore = 1.0;
      matchReasons.push('Reported same day');
    } else if (hoursDiff < 72) {
      timeScore = 0.7;
    } else if (hoursDiff < 168) { // 1 week
      timeScore = 0.4;
    } else {
      timeScore = 0.2;
    }
    totalScore += timeScore * 10;
    weights += 10;

    // Calculate final confidence
    let confidence = weights > 0 ? (totalScore / weights) * 100 : 0;

    // 7. Optional: Use AI for more accurate matching
    if (useAI && confidence > 30) {
      try {
        const aiResult = await calculateMatchConfidence(
          { 
            title: targetItem.title, 
            description: targetItem.description, 
            aiTags: targetItem.aiTags, 
            category: targetItem.category 
          },
          { 
            title: candidate.title, 
            description: candidate.description, 
            aiTags: candidate.aiTags, 
            category: candidate.category 
          }
        );
        // Weight AI analysis at 40%
        confidence = confidence * 0.6 + aiResult.confidence * 0.4;
        if (aiResult.confidence > 70) {
          matchReasons.push('AI high confidence');
        }
      } catch (error) {
        console.error('AI matching failed:', error);
      }
    }

    // Only include matches with >30% confidence
    if (confidence > 30) {
      results.push({
        item: candidate,
        confidence: Math.round(confidence),
        matchReasons,
      });
    }
  }

  // Sort by confidence, highest first
  return results.sort((a, b) => b.confidence - a.confidence);
}

// Quick match score without AI (for real-time suggestions)
export function quickMatchScore(item1: Item, item2: Item): number {
  if (item1.type === item2.type) return 0; // Must be opposite types
  if (item1.category !== item2.category) return 0;

  let score = 0;

  // Tag overlap (60%)
  score += calculateTagOverlap(item1.aiTags, item2.aiTags) * 60;

  // Title similarity (25%)
  score += calculateTextSimilarity(item1.title, item2.title) * 25;

  // Location (15%)
  if (item1.location && item2.location) {
    const distance = calculateDistance(
      item1.location.lat, item1.location.lng,
      item2.location.lat, item2.location.lng
    );
    if (distance < 5) score += 15;
    else if (distance < 10) score += 10;
    else if (distance < 20) score += 5;
  }

  return Math.round(score);
}
