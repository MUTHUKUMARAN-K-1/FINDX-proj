'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { 
  Search, ChevronRight, TrendingUp, Users, Clock, Shield, 
  Sparkles, Award, ArrowRight, MapPin, Navigation, Loader2
} from 'lucide-react';
import Header from '@/components/layout/Header';
import BottomNav from '@/components/layout/BottomNav';
import ItemCard from '@/components/features/ItemCard';
import { useLocation } from '@/contexts/LocationContext';
import { useItems } from '@/hooks/useItems';

const STATS = [
  { icon: TrendingUp, label: 'Recovery Rate', value: '78%', color: 'text-green-500' },
  { icon: Users, label: 'Active Users', value: '12.5K', color: 'text-blue-500' },
  { icon: Clock, label: 'Avg Recovery', value: '2.5 hrs', color: 'text-purple-500' },
  { icon: Shield, label: 'Value Saved', value: '₹45L+', color: 'text-amber-500' },
];

export default function HomePage() {
  const { items, loading: itemsLoading } = useItems();
  const [filter, setFilter] = useState<'all' | 'lost' | 'found'>('all');
  const { location, locationName, permissionStatus, requestLocation, loading } = useLocation();

  const filteredItems = items.filter(item => 
    filter === 'all' || item.type === filter
  );

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950">
      <Header showLocation={true} />

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-8">
        
        {/* Location Permission Banner - Show if not granted */}
        {permissionStatus !== 'granted' && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-3 p-4 bg-primary-50 dark:bg-primary-900/20 
                      border border-primary-200 dark:border-primary-800/30 rounded-xl"
          >
            <div className="w-10 h-10 rounded-full bg-primary-100 dark:bg-primary-500/20 
                          flex items-center justify-center flex-shrink-0">
              <Navigation className="w-5 h-5 text-primary-600 dark:text-primary-400" />
            </div>
            <div className="flex-1">
              <p className="font-medium text-neutral-900 dark:text-white text-sm">
                Enable location for better results
              </p>
              <p className="text-xs text-neutral-500 dark:text-neutral-400">
                Find lost items near you
              </p>
            </div>
            <button
              onClick={requestLocation}
              disabled={loading}
              className="btn btn-primary btn-icon-sm px-4 py-2 text-sm"
            >
              {loading ? 'Detecting...' : 'Enable'}
            </button>
          </motion.div>
        )}

        {/* Hero Section */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center py-6 sm:py-10"
        >
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight">
            <span className="text-neutral-900 dark:text-white">Lost in seconds, </span>
            <span className="gradient-text">found in minutes</span>
          </h1>
          <p className="mt-4 text-lg text-neutral-600 dark:text-neutral-400 max-w-2xl mx-auto">
            India's AI-powered recovery platform for items, pets & persons. 
            Report instantly, recover faster.
          </p>
        </motion.section>

        {/* Quick Action Cards */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="grid grid-cols-2 gap-4"
        >
          <Link href="/report/lost">
            <div className="feature-card feature-card-lost group cursor-pointer">
              <div className="flex flex-col items-center text-center">
                <div className="w-14 h-14 rounded-2xl bg-red-100 dark:bg-red-500/20 
                              flex items-center justify-center mb-3
                              group-hover:scale-110 transition-transform">
                  <span className="text-2xl">🔴</span>
                </div>
                <h3 className="font-semibold text-neutral-900 dark:text-white">
                  Report Lost
                </h3>
                <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1">
                  Item, Pet, or Person
                </p>
              </div>
            </div>
          </Link>

          <Link href="/report/found">
            <div className="feature-card feature-card-found group cursor-pointer">
              <div className="flex flex-col items-center text-center">
                <div className="w-14 h-14 rounded-2xl bg-green-100 dark:bg-green-500/20 
                              flex items-center justify-center mb-3
                              group-hover:scale-110 transition-transform">
                  <span className="text-2xl">🟢</span>
                </div>
                <h3 className="font-semibold text-neutral-900 dark:text-white">
                  Report Found
                </h3>
                <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1">
                  Help someone today
                </p>
              </div>
            </div>
          </Link>
        </motion.section>

        {/* Stats Banner */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="card-elevated p-4 sm:p-6"
        >
          <div className="grid grid-cols-4 gap-2 sm:gap-4">
            {STATS.map((stat, index) => (
              <div key={index} className="text-center">
                <stat.icon className={`w-5 h-5 mx-auto ${stat.color}`} />
                <p className={`font-bold text-lg sm:text-xl mt-1 ${stat.color}`}>
                  {stat.value}
                </p>
                <p className="text-[10px] sm:text-xs text-neutral-500 dark:text-neutral-400">
                  {stat.label}
                </p>
              </div>
            ))}
          </div>
        </motion.section>

        {/* AI Feature Banner */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="relative overflow-hidden rounded-2xl 
                    bg-gradient-to-r from-primary-50 to-blue-50 
                    dark:from-primary-900/20 dark:to-blue-900/20 
                    border border-primary-100 dark:border-primary-800/30 p-5"
        >
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-primary-100 dark:bg-primary-500/20 
                          flex items-center justify-center flex-shrink-0">
              <Sparkles className="w-6 h-6 text-primary-600 dark:text-primary-400" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-neutral-900 dark:text-white">
                Powered by Google Gemini AI
              </h3>
              <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-0.5">
                Auto-describe items, smart matching, scam detection
              </p>
            </div>
            <ArrowRight className="w-5 h-5 text-primary-400 hidden sm:block" />
          </div>
        </motion.section>

        {/* Filter Tabs + Items Feed Section */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-white flex items-center gap-2">
              <MapPin className="w-5 h-5 text-primary-500" />
              {location ? 'Near You' : 'Recent Items'}
            </h2>
            <Link href="/search" className="text-primary-600 dark:text-primary-400 
                                          text-sm font-medium flex items-center gap-1
                                          hover:underline">
              View all <ChevronRight className="w-4 h-4" />
            </Link>
          </div>

          {/* Filter Pills */}
          <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-2 scrollbar-hide">
            {(['all', 'lost', 'found'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`
                  px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap
                  transition-all duration-200
                  ${filter === f 
                    ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900' 
                    : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-300 border border-neutral-200 dark:border-neutral-700 hover:border-neutral-300'
                  }
                `}
              >
                {f === 'all' && '📋 All Items'}
                {f === 'lost' && '🔴 Lost'}
                {f === 'found' && '🟢 Found'}
              </button>
            ))}
          </div>

          {/* Items List */}
          <div className="space-y-3">
            {itemsLoading ? (
              // Loading skeleton
              <>
                {[1, 2, 3].map(i => (
                  <div key={i} className="card-elevated p-4 animate-pulse">
                    <div className="flex gap-4">
                      <div className="w-24 h-24 rounded-xl bg-neutral-200 dark:bg-neutral-700" />
                      <div className="flex-1 space-y-3">
                        <div className="h-4 bg-neutral-200 dark:bg-neutral-700 rounded w-3/4" />
                        <div className="h-3 bg-neutral-200 dark:bg-neutral-700 rounded w-full" />
                        <div className="h-3 bg-neutral-200 dark:bg-neutral-700 rounded w-1/2" />
                      </div>
                    </div>
                  </div>
                ))}
              </>
            ) : filteredItems.length > 0 ? (
              filteredItems.map((item, index) => (
                <ItemCard key={item.id} item={item} index={index} />
              ))
            ) : (
              <div className="text-center py-12 text-neutral-500">
                <p>No items found in your area</p>
                <Link href="/report" className="text-primary-500 hover:underline mt-2 inline-block">
                  Report an item
                </Link>
              </div>
            )}
          </div>
        </section>

        {/* Hero Program CTA */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <Link href="/profile">
            <div className="card-elevated p-5 group cursor-pointer">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-2xl 
                              bg-gradient-to-br from-amber-100 to-orange-100 
                              dark:from-amber-500/20 dark:to-orange-500/20
                              flex items-center justify-center flex-shrink-0
                              group-hover:scale-105 transition-transform">
                  <Award className="w-7 h-7 text-amber-600 dark:text-amber-400" />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-neutral-900 dark:text-white">
                    Become a FINDX Hero
                  </h3>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400">
                    Help others & earn badges, rewards, recognition
                  </p>
                </div>
                <ChevronRight className="w-5 h-5 text-neutral-300 dark:text-neutral-600 
                                        group-hover:text-amber-500 group-hover:translate-x-1 
                                        transition-all" />
              </div>
            </div>
          </Link>
        </motion.section>

        {/* Bottom spacing for mobile nav */}
        <div className="h-4" />
      </div>

      <BottomNav />
    </div>
  );
}
