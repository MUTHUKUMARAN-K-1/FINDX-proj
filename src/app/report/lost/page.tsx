'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { CheckCircle } from 'lucide-react';
import ReportForm from '@/components/features/ReportForm';
import { addItem } from '@/hooks/useItems';
import { AIGeneratedReport } from '@/types';

export default function ReportLostPage() {
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
        type: 'lost' as const,
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
        reward: report.reward || 0,
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
            Report Submitted! 🎉
          </h1>
          
          <p className="text-neutral-600 dark:text-neutral-400 mb-6">
            Your lost item report has been created and saved. We're already searching for matches 
            and will notify you as soon as we find something.
          </p>

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
        type="lost" 
        onSubmit={handleSubmit}
        onClose={() => router.back()}
      />
    </div>
  );
}
