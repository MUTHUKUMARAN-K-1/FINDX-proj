'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { CheckCircle, Award } from 'lucide-react';
import ReportForm from '@/components/features/ReportForm';
import { addItem } from '@/hooks/useItems';
import { AIGeneratedReport } from '@/types';

export default function ReportFoundPage() {
  const router = useRouter();
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [submittedId, setSubmittedId] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (report: AIGeneratedReport & { 
    images: string[]; 
    location: { lat: number; lng: number } | null;
    locationName: string;
    reward: number;
  }) => {
    setIsSubmitting(true);
    
    try {
      // Create the item object for Firebase
      const itemData = {
        type: 'found' as const,
        category: report.category,
        status: 'active' as const,
        title: report.title,
        description: report.description,
        aiTags: report.aiTags || [],
        images: report.images || [],
        location: report.location,
        locationName: report.locationName || 'Unknown location',
        radius: 5,
        reportedBy: 'user1', // TODO: Get from auth
        verificationQuestions: (report.suggestedQuestions || []).map(q => ({ question: q, answer: '' })),
      };

      console.log('Saving to Firebase:', itemData);
      
      // Save to Firebase
      const docId = await addItem(itemData);
      console.log('Saved with ID:', docId);
      
      setSubmittedId(docId);
      setIsSubmitted(true);
    } catch (error) {
      console.error('Error saving report:', error);
      alert('Failed to save report. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSubmitted) {
    return (
      <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 flex items-center justify-center p-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center max-w-md"
        >
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200, delay: 0.2 }}
            className="w-20 h-20 mx-auto mb-6 rounded-full bg-green-100 dark:bg-green-500/20 
                      flex items-center justify-center"
          >
            <CheckCircle className="w-10 h-10 text-green-500" />
          </motion.div>
          
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-3">
            Thank You, Hero! 🦸
          </h1>
          
          <p className="text-neutral-600 dark:text-neutral-400 mb-6">
            Your found item report has been saved. We're matching it with lost reports 
            and will connect you with the owner.
          </p>

          {/* Hero Points Earned */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="p-4 bg-gradient-to-r from-amber-50 to-orange-50 
                      dark:from-amber-900/20 dark:to-orange-900/20 
                      rounded-xl mb-6 border border-amber-200 dark:border-amber-800/30"
          >
            <div className="flex items-center justify-center gap-3">
              <Award className="w-6 h-6 text-amber-500" />
              <div className="text-left">
                <p className="text-xs text-amber-600 dark:text-amber-400 font-medium">You Earned</p>
                <p className="text-lg font-bold text-amber-700 dark:text-amber-300">+10 Hero Points</p>
              </div>
            </div>
          </motion.div>

          <div className="p-4 bg-primary-50 dark:bg-primary-500/10 rounded-xl mb-6">
            <p className="text-sm text-primary-700 dark:text-primary-300">
              <span className="font-medium">Report ID:</span> {submittedId}
            </p>
          </div>

          <div className="space-y-3">
            <button
              onClick={() => router.push(`/item/${submittedId}`)}
              className="w-full btn btn-primary"
            >
              View Your Report
            </button>
            <button
              onClick={() => router.push('/')}
              className="w-full btn btn-secondary"
            >
              Back to Home
            </button>
          </div>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950">
      <ReportForm 
        type="found" 
        onSubmit={handleSubmit}
        onClose={() => router.back()}
      />
    </div>
  );
}
