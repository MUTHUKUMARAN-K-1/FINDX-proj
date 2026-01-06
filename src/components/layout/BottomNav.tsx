'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { Home, Search, Plus, Bell, User } from 'lucide-react';

const navItems = [
  { href: '/', icon: Home, label: 'Home' },
  { href: '/search', icon: Search, label: 'Search' },
  { href: '/report', icon: Plus, label: 'Report', isMain: true },
  { href: '/notifications', icon: Bell, label: 'Alerts' },
  { href: '/profile', icon: User, label: 'Profile' },
];

export default function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="bottom-nav md:hidden">
      <div className="max-w-md mx-auto">
        <div className="flex items-center justify-around">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;

            if (item.isMain) {
              return (
                <Link key={item.href} href={item.href} className="relative -mt-5">
                  <motion.div
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="w-14 h-14 rounded-full 
                              bg-gradient-to-br from-primary-500 to-primary-600 
                              flex items-center justify-center 
                              shadow-lg shadow-primary-500/30
                              border-4 border-white dark:border-neutral-900"
                  >
                    <Icon className="w-6 h-6 text-white" strokeWidth={2.5} />
                  </motion.div>
                </Link>
              );
            }

            return (
              <Link key={item.href} href={item.href} className="nav-item relative py-2 px-3">
                <motion.div
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  className={`flex flex-col items-center ${
                    isActive 
                      ? 'text-primary-500' 
                      : 'text-neutral-500 dark:text-neutral-400'
                  }`}
                >
                  <Icon className="w-5 h-5" strokeWidth={isActive ? 2.5 : 2} />
                  <span className="text-[10px] mt-1 font-medium">{item.label}</span>
                  
                  {isActive && (
                    <motion.div
                      layoutId="nav-indicator"
                      className="absolute -bottom-0.5 w-1 h-1 bg-primary-500 rounded-full"
                      transition={{ type: 'spring', stiffness: 350, damping: 30 }}
                    />
                  )}
                </motion.div>
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
