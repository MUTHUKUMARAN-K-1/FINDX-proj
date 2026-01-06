import { GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } from '@google/generative-ai';
import { AIGeneratedReport, ItemCategory } from '@/types';

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(
  process.env.NEXT_PUBLIC_GEMINI_API_KEY || 'YOUR_GEMINI_API_KEY'
);

// Safety settings
const safetySettings = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
];

// Get the Gemini Pro Vision model for image analysis
const visionModel = genAI.getGenerativeModel({ 
  model: 'gemini-1.5-flash',
  safetySettings,
});

// Get the Gemini Pro model for text generation
const textModel = genAI.getGenerativeModel({ 
  model: 'gemini-1.5-flash',
  safetySettings,
});

/**
 * Analyze an image and generate a report using Gemini Vision
 */
export async function analyzeImageForReport(
  imageBase64: string,
  itemType: 'lost' | 'found'
): Promise<AIGeneratedReport> {
  const prompt = `You are an AI assistant for a lost and found platform in India called FINDX.
  
Analyze this image of a ${itemType} item/pet/person and provide the following information in JSON format:

{
  "title": "A short, descriptive title (max 50 chars)",
  "description": "A detailed description including appearance, distinguishing features, approximate size, condition (max 200 chars)",
  "category": "item" or "pet" or "person",
  "aiTags": ["array", "of", "relevant", "tags", "for", "searching"],
  "brand": "brand name if visible or identifiable (or null)",
  "color": "primary color(s)",
  "identifyingMarks": ["any", "unique", "marks", "or", "features"],
  "suggestedQuestions": ["verification questions that only the owner would know"]
}

Be specific and helpful. If it's a phone, try to identify the model. If it's a pet, describe breed, color, any collar or tags. If it's a person, describe clothing, approximate age (if appropriate), and any visible details.

Important: Return ONLY valid JSON, no markdown or extra text.`;

  try {
    const imagePart = {
      inlineData: {
        data: imageBase64.replace(/^data:image\/\w+;base64,/, ''),
        mimeType: 'image/jpeg',
      },
    };

    const result = await visionModel.generateContent([prompt, imagePart]);
    const response = await result.response;
    const text = response.text();

    // Parse JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        title: parsed.title || 'Unknown Item',
        description: parsed.description || 'No description available',
        category: validateCategory(parsed.category),
        aiTags: Array.isArray(parsed.aiTags) ? parsed.aiTags : [],
        brand: parsed.brand || undefined,
        color: parsed.color || undefined,
        identifyingMarks: Array.isArray(parsed.identifyingMarks) ? parsed.identifyingMarks : [],
        suggestedQuestions: Array.isArray(parsed.suggestedQuestions) ? parsed.suggestedQuestions : [],
      };
    }

    throw new Error('Failed to parse AI response');
  } catch (error) {
    console.error('Gemini Vision error:', error);
    return getDefaultReport(itemType);
  }
}

/**
 * Generate a report from voice/text description
 */
export async function generateReportFromText(
  description: string,
  itemType: 'lost' | 'found'
): Promise<AIGeneratedReport> {
  const prompt = `You are an AI assistant for a lost and found platform in India called FINDX.
  
Based on this ${itemType} item description: "${description}"

Generate a structured report in JSON format:

{
  "title": "A short, descriptive title (max 50 chars)",
  "description": "A detailed, clear description based on the input (max 200 chars)",
  "category": "item" or "pet" or "person",
  "aiTags": ["array", "of", "relevant", "tags", "for", "searching"],
  "brand": "brand name if mentioned (or null)",
  "color": "color if mentioned (or null)",
  "identifyingMarks": ["any", "unique", "features", "mentioned"],
  "suggestedQuestions": ["verification questions based on details given"]
}

Important: Return ONLY valid JSON, no markdown or extra text.`;

  try {
    const result = await textModel.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Parse JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        title: parsed.title || 'Unknown Item',
        description: parsed.description || description,
        category: validateCategory(parsed.category),
        aiTags: Array.isArray(parsed.aiTags) ? parsed.aiTags : [],
        brand: parsed.brand || undefined,
        color: parsed.color || undefined,
        identifyingMarks: Array.isArray(parsed.identifyingMarks) ? parsed.identifyingMarks : [],
        suggestedQuestions: Array.isArray(parsed.suggestedQuestions) ? parsed.suggestedQuestions : [],
      };
    }

    throw new Error('Failed to parse AI response');
  } catch (error) {
    console.error('Gemini text error:', error);
    return {
      title: description.slice(0, 50),
      description: description,
      category: 'item',
      aiTags: description.toLowerCase().split(' ').filter(w => w.length > 3),
      suggestedQuestions: [],
    };
  }
}

/**
 * Calculate match confidence between two items
 */
export async function calculateMatchConfidence(
  lostItem: { title: string; description: string; aiTags: string[]; category: string },
  foundItem: { title: string; description: string; aiTags: string[]; category: string }
): Promise<{ confidence: number; reasons: string[] }> {
  const prompt = `You are an AI assistant for matching lost and found items.

Compare these two items and determine if they could be the same:

LOST ITEM:
- Title: ${lostItem.title}
- Description: ${lostItem.description}
- Tags: ${lostItem.aiTags.join(', ')}
- Category: ${lostItem.category}

FOUND ITEM:
- Title: ${foundItem.title}
- Description: ${foundItem.description}
- Tags: ${foundItem.aiTags.join(', ')}
- Category: ${foundItem.category}

Respond with JSON only:
{
  "confidence": 0-100 (percentage match likelihood),
  "reasons": ["array", "of", "reasons", "for", "the", "confidence", "score"]
}

Consider: category match, color match, brand match, description similarity, tag overlap.
Be strict - only high confidence if multiple factors match.

Important: Return ONLY valid JSON.`;

  try {
    const result = await textModel.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        confidence: Math.min(100, Math.max(0, parsed.confidence || 0)),
        reasons: Array.isArray(parsed.reasons) ? parsed.reasons : [],
      };
    }

    return { confidence: 0, reasons: ['Unable to analyze'] };
  } catch (error) {
    console.error('Match calculation error:', error);
    return { confidence: 0, reasons: ['Analysis failed'] };
  }
}

// Helper functions
function validateCategory(category: string): ItemCategory {
  const valid = ['item', 'pet', 'person'];
  return valid.includes(category?.toLowerCase()) 
    ? (category.toLowerCase() as ItemCategory) 
    : 'item';
}

function getDefaultReport(itemType: 'lost' | 'found'): AIGeneratedReport {
  return {
    title: `${itemType === 'lost' ? 'Lost' : 'Found'} Item`,
    description: 'Unable to analyze image. Please provide a description.',
    category: 'item',
    aiTags: [],
    suggestedQuestions: [],
  };
}
