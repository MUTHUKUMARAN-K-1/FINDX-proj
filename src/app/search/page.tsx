'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { ArrowLeft, Search as SearchIcon, Filter, MapPin, X, SlidersHorizontal } from 'lucide-react';
import BottomNav from '@/components/layout/BottomNav';
import ItemCard from '@/components/features/ItemCard';
import { Item, ItemCategory } from '@/types';

// Mock data
const MOCK_ITEMS: Item[] = [
  {
    id: '1',
    type: 'lost',
    category: 'item',
    status: 'active',
    title: 'iPhone 15 Pro Max',
    description: 'Space Black, 256GB with blue leather case',
    aiTags: ['iphone', 'apple', 'phone'],
    images: ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'CIT Cafeteria',
    radius: 5,
    reportedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    reportedBy: 'user1',
    reward: 5000,
  },
  {
    id: '2',
    type: 'lost',
    category: 'pet',
    status: 'active',
    title: 'Golden Retriever - Max',
    description: 'Male, 3 years old, cream colored with red collar',
    aiTags: ['dog', 'golden retriever', 'pet'],
    images: ['https://images.unsplash.com/photo-1552053831-71594a27632d?w=400'],
    location: { lat: 12.9716, lng: 77.5946 },
    locationName: 'HSR Layout Park',
    radius: 10,
    reportedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
    reportedBy: 'user2',
    reward: 10000,
  },
];

export default function SearchPage() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [selectedType, setSelectedType] = useState<'all' | 'lost' | 'found'>('all');
  const [selectedCategory, setSelectedCategory] = useState<'all' | ItemCategory>('all');
  const [items] = useState(MOCK_ITEMS);

  const filteredItems = items.filter(item => {
    const matchesSearch = searchQuery === '' || 
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.aiTags.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()));
    
    const matchesType = selectedType === 'all' || item.type === selectedType;
    const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory;
    
    return matchesSearch && matchesType && matchesCategory;
  });

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 pb-24">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-white/95 dark:bg-neutral-900/95 backdrop-blur-xl 
                    border-b border-neutral-200 dark:border-neutral-800">
        <div className="flex items-center gap-3 px-4 py-3 max-w-4xl mx-auto">
          <button onClick={() => router.back()} 
                  className="p-2 -ml-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <ArrowLeft className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </button>

          {/* Search Input */}
          <div className="flex-1 relative">
            <SearchIcon className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search items, pets, locations..."
              className="input pl-10 pr-10 py-2.5 text-sm"
              autoFocus
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-1 
                          hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-full"
              >
                <X className="w-4 h-4 text-neutral-400" />
              </button>
            )}
          </div>

          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`p-2.5 rounded-xl border transition-colors ${
              showFilters 
                ? 'bg-neutral-900 dark:bg-white border-transparent text-white dark:text-neutral-900' 
                : 'bg-white dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-600 dark:text-neutral-400'
            }`}
          >
            <SlidersHorizontal className="w-5 h-5" />
          </button>
        </div>

        {/* Filters */}
        {showFilters && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="px-4 pb-4 max-w-4xl mx-auto space-y-4 border-t border-neutral-100 dark:border-neutral-800 pt-4"
          >
            {/* Type filter */}
            <div>
              <label className="text-xs font-medium text-neutral-500 dark:text-neutral-400 mb-2 block">
                Type
              </label>
              <div className="flex gap-2">
                {(['all', 'lost', 'found'] as const).map(type => (
                  <button
                    key={type}
                    onClick={() => setSelectedType(type)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                      selectedType === type
                        ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900'
                        : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400 border border-neutral-200 dark:border-neutral-700'
                    }`}
                  >
                    {type === 'all' && 'All'}
                    {type === 'lost' && '🔴 Lost'}
                    {type === 'found' && '🟢 Found'}
                  </button>
                ))}
              </div>
            </div>

            {/* Category filter */}
            <div>
              <label className="text-xs font-medium text-neutral-500 dark:text-neutral-400 mb-2 block">
                Category
              </label>
              <div className="flex gap-2 flex-wrap">
                {(['all', 'item', 'pet', 'person'] as const).map(cat => (
                  <button
                    key={cat}
                    onClick={() => setSelectedCategory(cat)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                      selectedCategory === cat
                        ? 'bg-neutral-900 dark:bg-white text-white dark:text-neutral-900'
                        : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400 border border-neutral-200 dark:border-neutral-700'
                    }`}
                  >
                    {cat === 'all' && 'All'}
                    {cat === 'item' && '📦 Items'}
                    {cat === 'pet' && '🐾 Pets'}
                    {cat === 'person' && '👤 Persons'}
                  </button>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </div>

      {/* Results */}
      <div className="px-4 py-6 max-w-4xl mx-auto space-y-4">
        {/* Location indicator */}
        <div className="flex items-center gap-2 text-neutral-500 dark:text-neutral-400 text-sm">
          <MapPin className="w-4 h-4" />
          <span>Showing results within 10 km</span>
        </div>

        {/* Count */}
        <p className="text-sm text-neutral-400 dark:text-neutral-500">
          {filteredItems.length} result{filteredItems.length !== 1 ? 's' : ''} found
        </p>

        {/* Items */}
        {filteredItems.length > 0 ? (
          <div className="space-y-3">
            {filteredItems.map((item, index) => (
              <ItemCard key={item.id} item={item} index={index} />
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 
                          flex items-center justify-center">
              <SearchIcon className="w-8 h-8 text-neutral-300 dark:text-neutral-600" />
            </div>
            <p className="text-neutral-600 dark:text-neutral-400 font-medium">No items found</p>
            <p className="text-neutral-400 dark:text-neutral-500 text-sm mt-1">
              Try adjusting your search or filters
            </p>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}
