'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { ArrowLeft, Plus, Filter, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react';
import Link from 'next/link';
import BottomNav from '@/components/layout/BottomNav';
import ItemCard from '@/components/features/ItemCard';
import { useUserItems } from '@/hooks/useItems';
import { ItemStatus } from '@/types';

export default function MyItemsPage() {
  const router = useRouter();
  // In production, get userId from auth
  const { items, loading } = useUserItems('user1');
  const [filter, setFilter] = useState<'all' | ItemStatus>('all');

  const filteredItems = items.filter(item => 
    filter === 'all' || item.status === filter
  );

  const getStatusIcon = (status: ItemStatus) => {
    switch (status) {
      case 'active':
        return <AlertCircle className="w-4 h-4 text-amber-500" />;
      case 'matched':
        return <Clock className="w-4 h-4 text-blue-500" />;
      case 'recovered':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'closed':
        return <XCircle className="w-4 h-4 text-neutral-400" />;
    }
  };

  const statusCounts = {
    all: items.length,
    active: items.filter(i => i.status === 'active').length,
    matched: items.filter(i => i.status === 'matched').length,
    recovered: items.filter(i => i.status === 'recovered').length,
    closed: items.filter(i => i.status === 'closed').length,
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
          <h1 className="font-semibold text-neutral-900 dark:text-white">My Reports</h1>
          <Link href="/report">
            <div className="p-2 rounded-full bg-primary-500 text-white">
              <Plus className="w-5 h-5" />
            </div>
          </Link>
        </div>
      </div>

      <div className="px-4 py-6 max-w-4xl mx-auto space-y-6">
        {/* Stats Summary */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="grid grid-cols-4 gap-3"
        >
          {[
            { label: 'Active', count: statusCounts.active, color: 'text-amber-500', bg: 'bg-amber-100 dark:bg-amber-500/20' },
            { label: 'Matched', count: statusCounts.matched, color: 'text-blue-500', bg: 'bg-blue-100 dark:bg-blue-500/20' },
            { label: 'Recovered', count: statusCounts.recovered, color: 'text-green-500', bg: 'bg-green-100 dark:bg-green-500/20' },
            { label: 'Closed', count: statusCounts.closed, color: 'text-neutral-400', bg: 'bg-neutral-100 dark:bg-neutral-800' },
          ].map((stat) => (
            <div key={stat.label} className={`p-3 rounded-xl ${stat.bg} text-center`}>
              <p className={`text-xl font-bold ${stat.color}`}>{stat.count}</p>
              <p className="text-xs text-neutral-500 dark:text-neutral-400">{stat.label}</p>
            </div>
          ))}
        </motion.div>

        {/* Filter Pills */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {(['all', 'active', 'matched', 'recovered', 'closed'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`
                px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap
                transition-all duration-200 flex items-center gap-2
                ${filter === f 
                  ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900' 
                  : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-300 border border-neutral-200 dark:border-neutral-700'
                }
              `}
            >
              {f !== 'all' && getStatusIcon(f as ItemStatus)}
              {f.charAt(0).toUpperCase() + f.slice(1)}
              <span className="text-xs opacity-60">({statusCounts[f]})</span>
            </button>
          ))}
        </div>

        {/* Items List */}
        {loading ? (
          <div className="space-y-3">
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
          </div>
        ) : filteredItems.length > 0 ? (
          <div className="space-y-3">
            {filteredItems.map((item, index) => (
              <ItemCard key={item.id} item={item} index={index} />
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 
                          flex items-center justify-center">
              <Filter className="w-8 h-8 text-neutral-300 dark:text-neutral-600" />
            </div>
            <p className="text-neutral-600 dark:text-neutral-400 font-medium">No reports found</p>
            <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-1">
              {filter === 'all' 
                ? 'You haven\'t created any reports yet' 
                : `No ${filter} reports`
              }
            </p>
            <Link href="/report">
              <button className="mt-4 btn btn-primary">
                <Plus className="w-4 h-4" />
                Create Report
              </button>
            </Link>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}
