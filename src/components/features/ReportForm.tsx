'use client';

import React, { useState, useRef, useCallback, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Camera, Mic, MicOff, Sparkles, MapPin, Gift, Loader2, X, 
  ImageIcon, Navigation, CheckCircle 
} from 'lucide-react';
import { analyzeImageForReport, generateReportFromText } from '@/lib/gemini';
import { fileToBase64 } from '@/lib/utils';
import { AIGeneratedReport, ItemType, ItemCategory } from '@/types';
import { useLocation } from '@/contexts/LocationContext';

interface ReportFormProps {
  type: ItemType;
  onSubmit: (report: AIGeneratedReport & { 
    images: string[]; 
    location: { lat: number; lng: number } | null;
    locationName: string;
    reward: number;
  }) => void;
  onClose?: () => void;
}

export default function ReportForm({ type, onSubmit, onClose }: ReportFormProps) {
  const { location, locationName: autoLocationName, loading: locationLoading, requestLocation, permissionStatus } = useLocation();
  
  const [step, setStep] = useState<'capture' | 'review'>('capture');
  const [images, setImages] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [voiceText, setVoiceText] = useState('');
  const [aiReport, setAiReport] = useState<AIGeneratedReport | null>(null);
  const [editedTitle, setEditedTitle] = useState('');
  const [editedDescription, setEditedDescription] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<ItemCategory>('item');
  const [manualLocationName, setManualLocationName] = useState('');
  const [useAutoLocation, setUseAutoLocation] = useState(true);
  const [reward, setReward] = useState(0);
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const recognitionRef = useRef<any>(null);

  // Auto-request location on mount if not granted
  useEffect(() => {
    if (permissionStatus === 'prompt') {
      requestLocation();
    }
  }, [permissionStatus, requestLocation]);

  // Handle image capture
  const handleImageCapture = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files?.length) return;

    setIsProcessing(true);
    
    try {
      const file = files[0];
      const base64 = await fileToBase64(file);
      setImages([base64]);

      // Analyze with Gemini
      const report = await analyzeImageForReport(base64, type);
      setAiReport(report);
      setEditedTitle(report.title);
      setEditedDescription(report.description);
      setSelectedCategory(report.category);
      setStep('review');
    } catch (error) {
      console.error('Image processing error:', error);
      // Still move to review with basic info
      setStep('review');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle voice input
  const toggleVoiceRecording = useCallback(() => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Voice recognition is not supported in your browser');
      return;
    }

    if (isRecording) {
      recognitionRef.current?.stop();
      setIsRecording(false);
      
      // Process voice text
      if (voiceText) {
        processVoiceInput(voiceText);
      }
    } else {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      recognitionRef.current = new SpeechRecognition();
      recognitionRef.current.continuous = true;
      recognitionRef.current.interimResults = true;
      recognitionRef.current.lang = 'en-IN';

      recognitionRef.current.onresult = (event: any) => {
        let transcript = '';
        for (let i = 0; i < event.results.length; i++) {
          transcript += event.results[i][0].transcript;
        }
        setVoiceText(transcript);
      };

      recognitionRef.current.onerror = (event: any) => {
        console.error('Speech recognition error:', event.error);
        setIsRecording(false);
      };

      recognitionRef.current.start();
      setIsRecording(true);
    }
  }, [isRecording, voiceText]);

  const processVoiceInput = async (text: string) => {
    setIsProcessing(true);
    try {
      const report = await generateReportFromText(text, type);
      setAiReport(report);
      setEditedTitle(report.title);
      setEditedDescription(report.description);
      setSelectedCategory(report.category);
      setStep('review');
    } catch (error) {
      console.error('Voice processing error:', error);
      setEditedDescription(text);
      setStep('review');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle form submission
  const handleSubmit = () => {
    if (!editedTitle) return;

    const finalLocationName = useAutoLocation ? autoLocationName : manualLocationName;
    const finalLocation = useAutoLocation && location ? { lat: location.lat, lng: location.lng } : null;

    onSubmit({
      title: editedTitle,
      description: editedDescription,
      category: selectedCategory,
      aiTags: aiReport?.aiTags || [],
      brand: aiReport?.brand,
      color: aiReport?.color,
      identifyingMarks: aiReport?.identifyingMarks,
      suggestedQuestions: aiReport?.suggestedQuestions,
      images,
      location: finalLocation,
      locationName: finalLocationName,
      reward,
    });
  };

  const isLost = type === 'lost';
  const effectiveLocationName = useAutoLocation ? autoLocationName : manualLocationName;

  return (
    <div className="min-h-screen bg-white dark:bg-neutral-950 md:min-h-0 md:rounded-2xl md:max-w-lg md:mx-auto">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-white/95 dark:bg-neutral-900/95 backdrop-blur-xl 
                    border-b border-neutral-200 dark:border-neutral-800 px-4 py-4">
        <div className="flex items-center justify-between">
          <h1 className="text-lg font-bold text-neutral-900 dark:text-white flex items-center gap-2">
            {isLost ? '🔴' : '🟢'} Report {isLost ? 'Lost' : 'Found'} Item
          </h1>
          {onClose && (
            <button onClick={onClose} className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
              <X className="w-5 h-5 text-neutral-500" />
            </button>
          )}
        </div>
      </div>

      <AnimatePresence mode="wait">
        {step === 'capture' ? (
          <motion.div
            key="capture"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            className="p-6 space-y-6"
          >
            {/* Image capture */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-3">
                📷 Capture or Upload Photo
              </label>
              
              <div
                onClick={() => fileInputRef.current?.click()}
                className="relative aspect-video bg-neutral-100 dark:bg-neutral-800 rounded-2xl 
                         border-2 border-dashed border-neutral-300 dark:border-neutral-700 
                         hover:border-primary-500 transition-colors cursor-pointer
                         flex flex-col items-center justify-center gap-3"
              >
                {images[0] ? (
                  <img src={images[0]} alt="Preview" className="w-full h-full object-cover rounded-2xl" />
                ) : (
                  <>
                    <div className="w-16 h-16 rounded-full bg-neutral-200 dark:bg-neutral-700 
                                  flex items-center justify-center">
                      <Camera className="w-8 h-8 text-neutral-400" />
                    </div>
                    <p className="text-neutral-500 dark:text-neutral-400 text-center px-4">
                      Tap to take photo or upload
                    </p>
                  </>
                )}

                {isProcessing && (
                  <div className="absolute inset-0 bg-white/90 dark:bg-neutral-900/90 rounded-2xl 
                                flex items-center justify-center">
                    <div className="flex flex-col items-center gap-3">
                      <Loader2 className="w-8 h-8 text-primary-500 animate-spin" />
                      <p className="text-neutral-600 dark:text-neutral-300 font-medium">AI is analyzing...</p>
                    </div>
                  </div>
                )}
              </div>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                capture="environment"
                onChange={handleImageCapture}
                className="hidden"
              />
            </div>

            {/* Voice input */}
            <div className="text-center">
              <p className="text-neutral-500 dark:text-neutral-400 mb-4">or describe by voice</p>
              
              <motion.button
                onClick={toggleVoiceRecording}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className={`w-20 h-20 rounded-full flex items-center justify-center mx-auto shadow-lg
                           ${isRecording 
                             ? 'bg-red-500 animate-pulse' 
                             : 'bg-gradient-to-br from-primary-500 to-primary-600'
                           }`}
              >
                {isRecording ? (
                  <MicOff className="w-8 h-8 text-white" />
                ) : (
                  <Mic className="w-8 h-8 text-white" />
                )}
              </motion.button>

              {isRecording && (
                <p className="mt-3 text-red-500 font-medium animate-pulse">Listening...</p>
              )}

              {voiceText && (
                <div className="mt-4 p-4 bg-neutral-100 dark:bg-neutral-800 rounded-xl text-left">
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">You said:</p>
                  <p className="text-neutral-800 dark:text-white mt-1">{voiceText}</p>
                </div>
              )}
            </div>

            {/* AI hint */}
            <div className="flex items-start gap-3 p-4 bg-primary-50 dark:bg-primary-500/10 rounded-xl">
              <Sparkles className="w-5 h-5 text-primary-600 dark:text-primary-400 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm text-primary-700 dark:text-primary-300 font-medium">AI-Powered</p>
                <p className="text-sm text-primary-600/80 dark:text-primary-400/80 mt-1">
                  Our AI will auto-identify the item and generate a description.
                </p>
              </div>
            </div>

            {/* Manual Entry Option */}
            <div className="text-center pt-4 border-t border-neutral-200 dark:border-neutral-800">
              <button
                onClick={() => setStep('review')}
                className="text-primary-600 dark:text-primary-400 text-sm font-medium hover:underline"
              >
                Skip to Manual Entry →
              </button>
            </div>
          </motion.div>
        ) : (
          <motion.div
            key="review"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="p-6 space-y-5"
          >
            {/* AI Generated Banner */}
            {aiReport && (
              <div className="flex items-center gap-2 px-4 py-2 bg-primary-50 dark:bg-primary-500/10 rounded-xl">
                <Sparkles className="w-4 h-4 text-primary-600 dark:text-primary-400" />
                <span className="text-sm text-primary-700 dark:text-primary-300 font-medium">AI Auto-Generated</span>
              </div>
            )}

            {/* Image preview */}
            {images[0] && (
              <div className="relative aspect-video rounded-xl overflow-hidden">
                <img src={images[0]} alt="Preview" className="w-full h-full object-cover" />
              </div>
            )}

            {/* Title */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                Title *
              </label>
              <input
                type="text"
                value={editedTitle}
                onChange={(e) => setEditedTitle(e.target.value)}
                className="input"
                placeholder="What is it?"
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                Description
              </label>
              <textarea
                value={editedDescription}
                onChange={(e) => setEditedDescription(e.target.value)}
                rows={3}
                className="input resize-none"
                placeholder="Describe the item..."
              />
            </div>

            {/* Category */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                Category
              </label>
              <div className="grid grid-cols-3 gap-3">
                {(['item', 'pet', 'person'] as ItemCategory[]).map((cat) => (
                  <button
                    key={cat}
                    onClick={() => setSelectedCategory(cat)}
                    className={`py-3 rounded-xl font-medium transition-all text-sm ${
                      selectedCategory === cat
                        ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900'
                        : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                    }`}
                  >
                    {cat === 'item' && '📦 Item'}
                    {cat === 'pet' && '🐾 Pet'}
                    {cat === 'person' && '👤 Person'}
                  </button>
                ))}
              </div>
            </div>

            {/* Location */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                <MapPin className="w-4 h-4 inline mr-1" />
                Location
              </label>
              
              {/* Auto vs Manual toggle */}
              <div className="flex gap-2 mb-3">
                <button
                  onClick={() => setUseAutoLocation(true)}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-2 ${
                    useAutoLocation
                      ? 'bg-primary-500 text-white'
                      : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                  }`}
                >
                  <Navigation className="w-4 h-4" />
                  Use GPS
                </button>
                <button
                  onClick={() => setUseAutoLocation(false)}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all ${
                    !useAutoLocation
                      ? 'bg-primary-500 text-white'
                      : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                  }`}
                >
                  Enter Manually
                </button>
              </div>

              {useAutoLocation ? (
                <div className="flex items-center gap-3 p-3 bg-neutral-100 dark:bg-neutral-800 rounded-xl">
                  {locationLoading ? (
                    <Loader2 className="w-5 h-5 text-primary-500 animate-spin" />
                  ) : location ? (
                    <CheckCircle className="w-5 h-5 text-green-500" />
                  ) : (
                    <MapPin className="w-5 h-5 text-neutral-400" />
                  )}
                  <span className="text-sm text-neutral-700 dark:text-neutral-300 flex-1">
                    {autoLocationName}
                  </span>
                  {permissionStatus !== 'granted' && (
                    <button
                      onClick={requestLocation}
                      className="text-xs text-primary-600 dark:text-primary-400 font-medium"
                    >
                      Enable
                    </button>
                  )}
                </div>
              ) : (
                <input
                  type="text"
                  value={manualLocationName}
                  onChange={(e) => setManualLocationName(e.target.value)}
                  className="input"
                  placeholder="e.g., CIT Cafeteria, Main Library"
                />
              )}
            </div>

            {/* Reward (only for lost items) */}
            {isLost && (
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                  <Gift className="w-4 h-4 inline mr-1" />
                  Reward (Optional)
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-400">₹</span>
                  <input
                    type="number"
                    value={reward || ''}
                    onChange={(e) => setReward(Number(e.target.value))}
                    className="input pl-8"
                    placeholder="0"
                  />
                </div>
              </div>
            )}

            {/* AI Tags */}
            {aiReport?.aiTags && aiReport.aiTags.length > 0 && (
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                  AI Tags
                </label>
                <div className="flex flex-wrap gap-2">
                  {aiReport.aiTags.map((tag, i) => (
                    <span key={i} className="badge badge-neutral">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Submit */}
            <div className="pt-4 space-y-3">
              <motion.button
                onClick={handleSubmit}
                disabled={!editedTitle}
                whileHover={{ scale: 1.01 }}
                whileTap={{ scale: 0.99 }}
                className="w-full btn btn-primary py-4 text-base disabled:opacity-50"
              >
                🚀 Submit Report
              </motion.button>
              
              <button
                onClick={() => {
                  setStep('capture');
                  setImages([]);
                  setAiReport(null);
                  setVoiceText('');
                }}
                className="w-full btn btn-secondary"
              >
                ← Go Back
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// Add type definitions for Speech Recognition
declare global {
  interface Window {
    SpeechRecognition: any;
    webkitSpeechRecognition: any;
  }
}
