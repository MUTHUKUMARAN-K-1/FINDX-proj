'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { motion } from 'framer-motion';
import { MapPin, Clock, Gift, ChevronRight } from 'lucide-react';
import { Item, CATEGORY_ICONS } from '@/types';
import { formatDistanceToNow } from '@/lib/utils';

interface ItemCardProps {
  item: Item;
  index?: number;
  variant?: 'default' | 'compact';
}

export default function ItemCard({ item, index = 0, variant = 'default' }: ItemCardProps) {
  const isLost = item.type === 'lost';
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
    >
      <Link href={`/item/${item.id}`}>
        <div className="item-card group">
          <div className={`flex ${variant === 'compact' ? 'gap-3' : 'gap-4'}`}>
            {/* Image */}
            <div className={`
              relative flex-shrink-0 rounded-xl overflow-hidden 
              bg-neutral-100 dark:bg-neutral-800
              ${variant === 'compact' ? 'w-20 h-20' : 'w-24 h-24 sm:w-28 sm:h-28'}
            `}>
              {item.images[0] ? (
                <Image
                  src={item.images[0]}
                  alt={item.title}
                  fill
                  className="object-cover group-hover:scale-105 transition-transform duration-300"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-3xl">
                  {CATEGORY_ICONS[item.category]}
                </div>
              )}
              
              {/* Type badge */}
              <div className={`
                absolute top-1.5 left-1.5 px-2 py-0.5 
                rounded-full text-[10px] font-semibold
                backdrop-blur-sm
                ${isLost 
                  ? 'bg-red-500/90 text-white' 
                  : 'bg-green-500/90 text-white'
                }
              `}>
                {isLost ? 'Lost' : 'Found'}
              </div>
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0 py-0.5">
              <h3 className="font-semibold text-neutral-900 dark:text-white 
                           text-base leading-tight
                           group-hover:text-primary-600 dark:group-hover:text-primary-400 
                           transition-colors line-clamp-1">
                {item.title}
              </h3>
              
              <p className="text-neutral-500 dark:text-neutral-400 
                          text-sm mt-1 line-clamp-2 leading-snug">
                {item.description}
              </p>

              {/* Meta info */}
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-2 
                            text-xs text-neutral-400 dark:text-neutral-500">
                <span className="flex items-center gap-1">
                  <MapPin className="w-3 h-3" />
                  <span className="truncate max-w-[120px]">{item.locationName || 'Unknown'}</span>
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {formatDistanceToNow(item.reportedAt)}
                </span>
              </div>

              {/* Reward */}
              {item.reward && item.reward > 0 && (
                <div className="mt-2 inline-flex items-center gap-1 
                              px-2 py-0.5 rounded-full
                              bg-amber-50 dark:bg-amber-500/10 
                              text-amber-600 dark:text-amber-400 
                              text-xs font-medium">
                  <Gift className="w-3 h-3" />
                  ₹{item.reward.toLocaleString()}
                </div>
              )}
            </div>

            {/* Arrow */}
            <div className="hidden sm:flex items-center pl-2">
              <ChevronRight className="w-5 h-5 text-neutral-300 dark:text-neutral-600 
                                      group-hover:text-primary-500 
                                      group-hover:translate-x-0.5 transition-all" />
            </div>
          </div>

          {/* Tags - only on default variant */}
          {variant === 'default' && item.aiTags && item.aiTags.length > 0 && (
            <div className="flex flex-wrap gap-1.5 mt-3 pt-3 
                          border-t border-neutral-100 dark:border-neutral-800">
              {item.aiTags.slice(0, 4).map((tag, i) => (
                <span key={i} className="badge badge-neutral text-[10px]">
                  {tag}
                </span>
              ))}
              {item.aiTags.length > 4 && (
                <span className="text-[10px] text-neutral-400">
                  +{item.aiTags.length - 4}
                </span>
              )}
            </div>
          )}
        </div>
      </Link>
    </motion.div>
  );
}
