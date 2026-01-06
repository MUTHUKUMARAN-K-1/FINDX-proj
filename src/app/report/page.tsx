'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { ArrowLeft, Search, Sparkles, Clock, MapPin, Camera, AlertTriangle } from 'lucide-react';
import BottomNav from '@/components/layout/BottomNav';

export default function ReportPage() {
  const router = useRouter();

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 pb-24">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-white/95 dark:bg-neutral-900/95 backdrop-blur-xl 
                    border-b border-neutral-200 dark:border-neutral-800">
        <div className="flex items-center justify-between px-4 py-3 max-w-lg mx-auto">
          <button onClick={() => router.back()} 
                  className="p-2 -ml-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <ArrowLeft className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </button>
          <h1 className="font-semibold text-neutral-900 dark:text-white">Create Report</h1>
          <div className="w-10" />
        </div>
      </div>

      <div className="px-4 py-8 max-w-lg mx-auto">
        {/* Hero */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-2xl sm:text-3xl font-bold text-neutral-900 dark:text-white mb-2">
            What happened?
          </h1>
          <p className="text-neutral-500 dark:text-neutral-400">
            Select the type of report you want to create
          </p>
        </motion.div>

        {/* Options */}
        <div className="space-y-4">
          {/* Lost Option */}
          <Link href="/report/lost">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.99 }}
              className="feature-card feature-card-lost cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-red-100 dark:bg-red-500/20 
                              flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">🔴</span>
                </div>
                <div>
                  <h2 className="text-lg font-bold text-neutral-900 dark:text-white">
                    I Lost Something
                  </h2>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">
                    Report your lost item, pet, or person. Our AI will help create a detailed report.
                  </p>
                  <div className="flex items-center gap-2 mt-3 text-red-600 dark:text-red-400 text-sm font-medium">
                    <Sparkles className="w-4 h-4" />
                    AI-powered instant matching
                  </div>
                </div>
              </div>
            </motion.div>
          </Link>

          {/* Found Option */}
          <Link href="/report/found">
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.99 }}
              className="feature-card feature-card-found cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-green-100 dark:bg-green-500/20 
                              flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">🟢</span>
                </div>
                <div>
                  <h2 className="text-lg font-bold text-neutral-900 dark:text-white">
                    I Found Something
                  </h2>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">
                    Report an item you found. Help reunite it with its owner and earn Hero points!
                  </p>
                  <div className="flex items-center gap-2 mt-3 text-green-600 dark:text-green-400 text-sm font-medium">
                    <Search className="w-4 h-4" />
                    Automatic owner matching
                  </div>
                </div>
              </div>
            </motion.div>
          </Link>

          {/* Emergency Option */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="p-5 rounded-2xl bg-gradient-to-br from-rose-50 to-pink-50 
                      dark:from-rose-900/10 dark:to-pink-900/10 
                      border border-rose-200 dark:border-rose-800/30"
          >
            <div className="flex items-start gap-4">
              <div className="w-14 h-14 rounded-2xl bg-rose-100 dark:bg-rose-500/20 
                            flex items-center justify-center flex-shrink-0">
                <AlertTriangle className="w-6 h-6 text-rose-500" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-neutral-900 dark:text-white">
                  Missing Person
                </h2>
                <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">
                  Report a missing person. This will trigger an emergency alert to nearby users.
                </p>
                <Link 
                  href="/report/lost?category=person"
                  className="inline-flex items-center gap-2 mt-3 text-rose-600 dark:text-rose-400 
                           text-sm font-medium hover:underline"
                >
                  Create Emergency Alert →
                </Link>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Tips */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-8 card-elevated p-5"
        >
          <h3 className="font-semibold text-neutral-900 dark:text-white mb-3 flex items-center gap-2">
            <span className="text-lg">💡</span> Reporting Tips
          </h3>
          <ul className="space-y-3">
            {[
              { icon: Clock, text: 'Report as soon as possible - first hours are crucial' },
              { icon: MapPin, text: 'Include the exact location where you last saw the item' },
              { icon: Camera, text: 'Add a clear photo - our AI will identify it faster' },
            ].map((tip, i) => (
              <li key={i} className="flex items-start gap-3 text-sm text-neutral-600 dark:text-neutral-400">
                <tip.icon className="w-4 h-4 text-primary-500 flex-shrink-0 mt-0.5" />
                <span>{tip.text}</span>
              </li>
            ))}
          </ul>
        </motion.div>
      </div>

      <BottomNav />
    </div>
  );
}
