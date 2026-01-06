'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { ArrowLeft, Sparkles, ChevronRight, CheckCircle, XCircle, Clock } from 'lucide-react';
import BottomNav from '@/components/layout/BottomNav';
import { Item } from '@/types';
import { formatDistanceToNow } from '@/lib/utils';

// Mock matches data
const MOCK_MATCHES = [
  {
    id: 'match-1',
    lostItem: {
      id: '1',
      title: 'iPhone 15 Pro Max',
      images: ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
      locationName: 'CIT Cafeteria',
      reportedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    },
    foundItem: {
      id: '3',
      title: 'iPhone Found Near Library',
      images: ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
      locationName: 'CIT Library',
      reportedAt: new Date(Date.now() - 30 * 60 * 1000),
    },
    confidence: 87,
    status: 'pending',
    matchReasons: ['Same category', 'Very close (0.5km)', 'Matching AI tags', 'Reported same day'],
    createdAt: new Date(Date.now() - 20 * 60 * 1000),
  },
  {
    id: 'match-2',
    lostItem: {
      id: '5',
      title: 'MacBook Pro 14"',
      images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca4?w=400'],
      locationName: 'CIT Computer Lab',
      reportedAt: new Date(Date.now() - 4 * 60 * 60 * 1000),
    },
    foundItem: {
      id: '6',
      title: 'Laptop Found in Parking',
      images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca4?w=400'],
      locationName: 'Parking Lot A',
      reportedAt: new Date(Date.now() - 3 * 60 * 60 * 1000),
    },
    confidence: 72,
    status: 'pending',
    matchReasons: ['Same category', 'Nearby (1.2km)', 'Similar description'],
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
  },
];

export default function MatchesPage() {
  const router = useRouter();
  const [matches, setMatches] = useState(MOCK_MATCHES);
  const [filter, setFilter] = useState<'all' | 'pending' | 'confirmed' | 'rejected'>('all');

  const filteredMatches = matches.filter(m => 
    filter === 'all' || m.status === filter
  );

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'confirmed':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <Clock className="w-5 h-5 text-amber-500" />;
    }
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
          <h1 className="font-semibold text-neutral-900 dark:text-white flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-primary-500" />
            AI Matches
          </h1>
          <div className="w-10" />
        </div>
      </div>

      <div className="px-4 py-6 max-w-4xl mx-auto space-y-6">
        {/* Info Banner */}
        <div className="p-4 bg-primary-50 dark:bg-primary-900/20 rounded-xl 
                       border border-primary-200 dark:border-primary-800/30">
          <p className="text-sm text-primary-700 dark:text-primary-300">
            <span className="font-medium">AI Match Algorithm</span> analyzes location, description, 
            time, and visual similarity to find potential matches.
          </p>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {(['all', 'pending', 'confirmed', 'rejected'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`
                px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap
                transition-all duration-200
                ${filter === f 
                  ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900' 
                  : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-300 border border-neutral-200 dark:border-neutral-700'
                }
              `}
            >
              {f === 'all' && '📋 All'}
              {f === 'pending' && '⏳ Pending'}
              {f === 'confirmed' && '✅ Confirmed'}
              {f === 'rejected' && '❌ Rejected'}
            </button>
          ))}
        </div>

        {/* Matches List */}
        <div className="space-y-4">
          {filteredMatches.length > 0 ? (
            filteredMatches.map((match, index) => (
              <motion.div
                key={match.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
                className="card-elevated p-5"
              >
                {/* Match header */}
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <div className={`
                      px-3 py-1 rounded-full text-sm font-semibold
                      ${match.confidence >= 80 
                        ? 'bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-400' 
                        : match.confidence >= 60
                          ? 'bg-amber-100 dark:bg-amber-500/20 text-amber-700 dark:text-amber-400'
                          : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                      }
                    `}>
                      {match.confidence}% Match
                    </div>
                    {getStatusIcon(match.status)}
                  </div>
                  <span className="text-xs text-neutral-400">
                    {formatDistanceToNow(match.createdAt)}
                  </span>
                </div>

                {/* Items comparison */}
                <div className="grid grid-cols-2 gap-4">
                  {/* Lost Item */}
                  <div className="space-y-2">
                    <span className="text-xs font-medium text-red-500 uppercase">Lost</span>
                    <div className="aspect-square rounded-xl overflow-hidden bg-neutral-100 dark:bg-neutral-800">
                      <img 
                        src={match.lostItem.images[0]} 
                        alt={match.lostItem.title}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <p className="text-sm font-medium text-neutral-900 dark:text-white line-clamp-1">
                      {match.lostItem.title}
                    </p>
                    <p className="text-xs text-neutral-500 dark:text-neutral-400">
                      {match.lostItem.locationName}
                    </p>
                  </div>

                  {/* Found Item */}
                  <div className="space-y-2">
                    <span className="text-xs font-medium text-green-500 uppercase">Found</span>
                    <div className="aspect-square rounded-xl overflow-hidden bg-neutral-100 dark:bg-neutral-800">
                      <img 
                        src={match.foundItem.images[0]} 
                        alt={match.foundItem.title}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <p className="text-sm font-medium text-neutral-900 dark:text-white line-clamp-1">
                      {match.foundItem.title}
                    </p>
                    <p className="text-xs text-neutral-500 dark:text-neutral-400">
                      {match.foundItem.locationName}
                    </p>
                  </div>
                </div>

                {/* Match Reasons */}
                <div className="mt-4 pt-4 border-t border-neutral-100 dark:border-neutral-800">
                  <div className="flex flex-wrap gap-2">
                    {match.matchReasons.map((reason, i) => (
                      <span key={i} className="badge badge-neutral text-xs">
                        {reason}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Actions */}
                {match.status === 'pending' && (
                  <div className="flex gap-3 mt-4">
                    <button className="flex-1 btn btn-secondary py-2 text-sm">
                      ❌ Not a Match
                    </button>
                    <button className="flex-1 btn btn-primary py-2 text-sm">
                      ✅ Confirm Match
                    </button>
                  </div>
                )}
              </motion.div>
            ))
          ) : (
            <div className="text-center py-16">
              <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 
                            flex items-center justify-center">
                <Sparkles className="w-8 h-8 text-neutral-300 dark:text-neutral-600" />
              </div>
              <p className="text-neutral-600 dark:text-neutral-400 font-medium">No matches yet</p>
              <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-1">
                We'll notify you when we find potential matches
              </p>
            </div>
          )}
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
