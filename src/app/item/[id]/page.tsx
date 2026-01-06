'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { 
  ArrowLeft, MapPin, Clock, Gift, Share2, Flag, 
  MessageCircle, Phone, ChevronRight, Sparkles, Shield, AlertTriangle, X
} from 'lucide-react';
import BottomNav from '@/components/layout/BottomNav';
import { formatDistanceToNow } from '@/lib/utils';
import { Item, CATEGORY_ICONS } from '@/types';

// Mock data - In real app, fetch from Firebase
const MOCK_ITEM: Item = {
  id: '1',
  type: 'lost',
  category: 'item',
  status: 'active',
  title: 'iPhone 15 Pro Max',
  description: 'Space Black, 256GB. Has a small crack on the top right corner of the screen. Blue leather case with card slots. Last seen in the cafeteria during lunch break around 1 PM.',
  aiTags: ['iphone', 'apple', 'phone', 'space black', 'cracked screen', 'leather case'],
  images: ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800'],
  location: { lat: 12.9716, lng: 77.5946 },
  locationName: 'CIT Cafeteria, Ground Floor',
  radius: 5,
  reportedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
  reportedBy: 'user1',
  reward: 5000,
  verificationQuestions: [
    { question: 'What is the phone case color?', answer: 'Blue' },
    { question: 'What is the lock screen wallpaper?', answer: 'Mountains' },
  ],
};

export default function ItemDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [item] = useState<Item>(MOCK_ITEM);
  const [showClaimModal, setShowClaimModal] = useState(false);
  const [claimMessage, setClaimMessage] = useState('');

  const isLost = item.type === 'lost';

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: `${isLost ? 'Lost' : 'Found'}: ${item.title}`,
          text: item.description,
          url: window.location.href,
        });
      } catch (err) {
        console.log('Share failed:', err);
      }
    } else {
      navigator.clipboard.writeText(window.location.href);
      alert('Link copied to clipboard!');
    }
  };

  const handleClaim = () => {
    // TODO: Submit claim to Firebase
    alert('Claim submitted! The owner will be notified and may contact you.');
    setShowClaimModal(false);
    setClaimMessage('');
  };

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 pb-24">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-white/95 dark:bg-neutral-900/95 backdrop-blur-xl 
                    border-b border-neutral-200 dark:border-neutral-800">
        <div className="flex items-center justify-between px-4 py-3 max-w-4xl mx-auto">
          <button onClick={() => router.back()} 
                  className="p-2 -ml-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <ArrowLeft className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </button>
          <div className="flex items-center gap-2">
            <button onClick={handleShare} 
                    className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
              <Share2 className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
            </button>
            <button className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
              <Flag className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
            </button>
          </div>
        </div>
      </div>

      {/* Main Image */}
      <div className="relative aspect-square md:aspect-video max-h-80 bg-neutral-100 dark:bg-neutral-800">
        <img 
          src={item.images[0]} 
          alt={item.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
        
        {/* Status badge */}
        <div className={`absolute top-4 left-4 px-3 py-1.5 rounded-full text-sm font-semibold backdrop-blur-sm ${
          isLost ? 'bg-red-500/90 text-white' : 'bg-green-500/90 text-white'
        }`}>
          {isLost ? '🔴 Lost' : '🟢 Found'}
        </div>

        {/* Category badge */}
        <div className="absolute top-4 right-4 px-3 py-1.5 rounded-full text-sm font-medium 
                       bg-black/50 backdrop-blur-sm text-white">
          {CATEGORY_ICONS[item.category]} {item.category}
        </div>
      </div>

      {/* Content */}
      <div className="px-4 max-w-4xl mx-auto -mt-6 relative z-10 space-y-4">
        {/* Title Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card-elevated p-5"
        >
          <h1 className="text-xl sm:text-2xl font-bold text-neutral-900 dark:text-white">
            {item.title}
          </h1>
          
          <div className="flex flex-wrap items-center gap-4 mt-3 text-sm text-neutral-500 dark:text-neutral-400">
            <span className="flex items-center gap-1.5">
              <MapPin className="w-4 h-4 text-primary-500" />
              {item.locationName}
            </span>
            <span className="flex items-center gap-1.5">
              <Clock className="w-4 h-4" />
              {formatDistanceToNow(item.reportedAt)}
            </span>
          </div>

          {/* Reward */}
          {item.reward && item.reward > 0 && (
            <div className="mt-4 p-4 bg-gradient-to-r from-amber-50 to-orange-50 
                          dark:from-amber-900/20 dark:to-orange-900/20 
                          rounded-xl border border-amber-200 dark:border-amber-800/30">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-amber-100 dark:bg-amber-500/20 
                              flex items-center justify-center">
                  <Gift className="w-6 h-6 text-amber-600 dark:text-amber-400" />
                </div>
                <div>
                  <p className="text-xs text-amber-600 dark:text-amber-400 font-medium">Reward</p>
                  <p className="text-2xl font-bold text-amber-700 dark:text-amber-300">
                    ₹{item.reward.toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          )}
        </motion.div>

        {/* Description */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="card-elevated p-5"
        >
          <h2 className="font-semibold text-neutral-900 dark:text-white mb-3">Description</h2>
          <p className="text-neutral-600 dark:text-neutral-400 leading-relaxed">
            {item.description}
          </p>

          {/* Tags */}
          {item.aiTags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4 pt-4 border-t border-neutral-100 dark:border-neutral-800">
              {item.aiTags.map((tag, i) => (
                <span key={i} className="badge badge-neutral">
                  #{tag}
                </span>
              ))}
            </div>
          )}
        </motion.div>

        {/* AI Match Banner */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="p-4 bg-gradient-to-r from-purple-50 to-pink-50 
                    dark:from-purple-900/20 dark:to-pink-900/20 
                    rounded-xl border border-purple-200 dark:border-purple-800/30"
        >
          <div className="flex items-center gap-3">
            <Sparkles className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            <div className="flex-1">
              <p className="font-medium text-neutral-900 dark:text-white">AI is searching for matches</p>
              <p className="text-sm text-neutral-500 dark:text-neutral-400">
                We'll notify you when we find potential matches
              </p>
            </div>
          </div>
        </motion.div>

        {/* Safety Warning (for person category) */}
        {item.category === 'person' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
            className="p-4 bg-amber-50 dark:bg-amber-900/20 rounded-xl 
                      border border-amber-200 dark:border-amber-800/30"
          >
            <div className="flex items-start gap-3">
              <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-medium text-amber-800 dark:text-amber-300">Safety First</p>
                <p className="text-sm text-amber-700 dark:text-amber-400/80 mt-1">
                  If you spot this person, please contact authorities immediately. 
                  Do not approach if the situation seems unsafe.
                </p>
              </div>
            </div>
          </motion.div>
        )}

        {/* Verification Shield */}
        {item.verificationQuestions && item.verificationQuestions.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="card-elevated p-5"
          >
            <div className="flex items-center gap-3 mb-2">
              <Shield className="w-5 h-5 text-green-600 dark:text-green-400" />
              <h2 className="font-semibold text-neutral-900 dark:text-white">Verification Protected</h2>
            </div>
            <p className="text-sm text-neutral-500 dark:text-neutral-400">
              This item has {item.verificationQuestions.length} verification question(s) 
              to prove ownership before claiming.
            </p>
          </motion.div>
        )}

        {/* Action Buttons */}
        <div className="space-y-3 pt-2 pb-4">
          <motion.button
            onClick={() => setShowClaimModal(true)}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
            className="w-full btn btn-primary py-4 text-base"
          >
            <MessageCircle className="w-5 h-5" />
            {isLost ? 'I Found This!' : 'This is Mine!'}
          </motion.button>

          <button className="w-full btn btn-secondary py-3">
            <Phone className="w-5 h-5" />
            Contact Reporter
          </button>
        </div>

        {/* Last Updated */}
        <p className="text-center text-xs text-neutral-400 dark:text-neutral-500 pb-4">
          Report ID: {item.id} • Last updated {formatDistanceToNow(item.reportedAt)}
        </p>
      </div>

      {/* Claim Modal */}
      {showClaimModal && (
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center 
                       bg-black/50 backdrop-blur-sm">
          <motion.div
            initial={{ opacity: 0, y: 100 }}
            animate={{ opacity: 1, y: 0 }}
            className="w-full max-w-lg bg-white dark:bg-neutral-900 
                      rounded-t-3xl md:rounded-3xl p-6 shadow-2xl"
          >
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-neutral-900 dark:text-white">
                {isLost ? 'I Found This Item' : 'Claim This Item'}
              </h2>
              <button 
                onClick={() => setShowClaimModal(false)}
                className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800"
              >
                <X className="w-5 h-5 text-neutral-500" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
                  Your Message
                </label>
                <textarea
                  value={claimMessage}
                  onChange={(e) => setClaimMessage(e.target.value)}
                  rows={4}
                  className="input resize-none"
                  placeholder={isLost 
                    ? "Describe where and when you found it..."
                    : "Describe how you can prove this is yours..."
                  }
                />
              </div>

              {!isLost && item.verificationQuestions && (
                <div className="p-4 bg-neutral-100 dark:bg-neutral-800 rounded-xl">
                  <p className="text-sm text-neutral-600 dark:text-neutral-400 flex items-center gap-2">
                    <Shield className="w-4 h-4 text-green-500" />
                    You'll need to answer verification questions
                  </p>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  onClick={() => setShowClaimModal(false)}
                  className="flex-1 btn btn-secondary"
                >
                  Cancel
                </button>
                <button
                  onClick={handleClaim}
                  className="flex-1 btn btn-primary"
                >
                  Submit
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}

      <BottomNav />
    </div>
  );
}
