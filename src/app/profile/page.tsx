'use client';

import React from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { 
  ArrowLeft, Settings, Award, ChevronRight, Shield, 
  Bell, LogOut, Edit2, Mail, Phone
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import BottomNav from '@/components/layout/BottomNav';
import ThemeToggle from '@/components/ui/ThemeToggle';
import { getHeroLevel } from '@/lib/utils';

// Mock user data
const MOCK_USER = {
  id: 'user1',
  displayName: 'Rahul Kumar',
  email: 'rahul@cit.edu',
  photoURL: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  phone: '+91 98765 43210',
  totalFinds: 23,
  totalReports: 8,
  reputationScore: 95,
  badges: ['early_adopter', 'top_finder', 'helpful'],
  organizationName: 'Chennai Institute of Technology',
  role: 'member',
  memberSince: new Date('2024-06-15'),
};

export default function ProfilePage() {
  const router = useRouter();
  const user = MOCK_USER;
  const heroInfo = getHeroLevel(user.totalFinds);

  const stats = [
    { label: 'Items Found', value: user.totalFinds, emoji: '🔍' },
    { label: 'Reports Made', value: user.totalReports, emoji: '📝' },
    { label: 'Reputation', value: `${user.reputationScore}%`, emoji: '⭐' },
  ];

  const menuItems = [
    { icon: Edit2, label: 'Edit Profile', href: '/profile/edit' },
    { icon: Bell, label: 'Notification Settings', href: '/profile/notifications' },
    { icon: Shield, label: 'Privacy & Security', href: '/profile/privacy' },
    { icon: Award, label: 'My Badges', href: '/profile/badges' },
    { icon: Settings, label: 'App Settings', href: '/settings' },
  ];

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
          <h1 className="font-semibold text-neutral-900 dark:text-white">Profile</h1>
          <ThemeToggle size="sm" />
        </div>
      </div>

      <div className="px-4 py-6 space-y-6 max-w-lg mx-auto">
        {/* Profile Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card-elevated p-6 text-center"
        >
          {/* Avatar */}
          <div className="relative w-20 h-20 mx-auto mb-4">
            <img 
              src={user.photoURL} 
              alt={user.displayName}
              className="w-full h-full rounded-full object-cover 
                       border-4 border-white dark:border-neutral-800 shadow-lg"
            />
            <div className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full 
                          bg-white dark:bg-neutral-800 shadow-md
                          flex items-center justify-center text-lg 
                          border-2 border-white dark:border-neutral-800">
              {heroInfo.badge}
            </div>
          </div>

          <h2 className="text-xl font-bold text-neutral-900 dark:text-white">
            {user.displayName}
          </h2>
          
          <div className="flex items-center justify-center gap-1 mt-1 text-neutral-500 dark:text-neutral-400">
            <Mail className="w-3.5 h-3.5" />
            <span className="text-sm">{user.email}</span>
          </div>
          
          {user.organizationName && (
            <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 
                          bg-primary-50 dark:bg-primary-500/10 
                          text-primary-600 dark:text-primary-400 
                          rounded-full text-sm font-medium">
              🏫 {user.organizationName}
            </div>
          )}
        </motion.div>

        {/* Hero Level Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="card-elevated p-5 bg-gradient-to-br from-amber-50 to-orange-50 
                    dark:from-amber-900/10 dark:to-orange-900/10 
                    border-amber-200 dark:border-amber-800/30"
        >
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-xl 
                          bg-gradient-to-br from-amber-400 to-orange-500 
                          flex items-center justify-center shadow-lg">
              <span className="text-2xl">{heroInfo.badge}</span>
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-wide">
                  Hero Level {heroInfo.level}
                </span>
              </div>
              <h3 className="text-lg font-bold text-neutral-900 dark:text-white">
                {heroInfo.name}
              </h3>
              
              {/* Progress bar */}
              <div className="mt-2">
                <div className="h-2 bg-amber-200/50 dark:bg-amber-900/30 rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${heroInfo.progress}%` }}
                    transition={{ duration: 1, delay: 0.3 }}
                    className="h-full bg-gradient-to-r from-amber-400 to-orange-500 rounded-full"
                  />
                </div>
                <p className="text-xs text-amber-700 dark:text-amber-400/70 mt-1">
                  {user.totalFinds} / {heroInfo.nextLevelAt} finds to next level
                </p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="grid grid-cols-3 gap-3"
        >
          {stats.map((stat, index) => (
            <div key={index} className="card-elevated p-4 text-center">
              <span className="text-2xl">{stat.emoji}</span>
              <p className="text-xl font-bold text-neutral-900 dark:text-white mt-1">
                {stat.value}
              </p>
              <p className="text-xs text-neutral-500 dark:text-neutral-400">
                {stat.label}
              </p>
            </div>
          ))}
        </motion.div>

        {/* Badges */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="card-elevated p-5"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-neutral-900 dark:text-white flex items-center gap-2">
              <Award className="w-5 h-5 text-primary-500" />
              Badges Earned
            </h3>
            <Link href="/profile/badges" 
                  className="text-primary-600 dark:text-primary-400 text-sm font-medium">
              View All
            </Link>
          </div>
          
          <div className="flex gap-4">
            {[
              { emoji: '🌟', name: 'Early Bird', bg: 'bg-blue-100 dark:bg-blue-500/20' },
              { emoji: '🦸', name: 'Hero', bg: 'bg-green-100 dark:bg-green-500/20' },
              { emoji: '💪', name: 'Helpful', bg: 'bg-purple-100 dark:bg-purple-500/20' },
              { emoji: '🔒', name: 'Locked', bg: 'bg-neutral-100 dark:bg-neutral-800', locked: true },
            ].map((badge, i) => (
              <div key={i} className={`flex flex-col items-center ${badge.locked ? 'opacity-40' : ''}`}>
                <div className={`w-12 h-12 rounded-full ${badge.bg} flex items-center justify-center text-xl`}>
                  {badge.emoji}
                </div>
                <span className="text-[10px] text-neutral-500 dark:text-neutral-400 mt-1 text-center">
                  {badge.name}
                </span>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Menu Items */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="card-elevated overflow-hidden"
        >
          {menuItems.map((item, index) => (
            <Link
              key={index}
              href={item.href}
              className="flex items-center gap-4 p-4 
                        hover:bg-neutral-50 dark:hover:bg-neutral-800/50 
                        transition-colors border-b border-neutral-100 dark:border-neutral-800
                        last:border-b-0"
            >
              <item.icon className="w-5 h-5 text-neutral-400" />
              <span className="flex-1 text-neutral-700 dark:text-neutral-300">
                {item.label}
              </span>
              <ChevronRight className="w-5 h-5 text-neutral-300 dark:text-neutral-600" />
            </Link>
          ))}
        </motion.div>

        {/* Logout */}
        <button className="w-full flex items-center justify-center gap-2 p-4 
                         text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 
                         rounded-xl transition-colors font-medium">
          <LogOut className="w-5 h-5" />
          Sign Out
        </button>

        {/* Footer */}
        <p className="text-center text-xs text-neutral-400 dark:text-neutral-500">
          Member since {user.memberSince.toLocaleDateString('en-IN', { month: 'long', year: 'numeric' })}
        </p>
      </div>

      <BottomNav />
    </div>
  );
}
