'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { MapPin, Bell, Loader2, RefreshCw, Search, Plus, User, Home } from 'lucide-react';
import ThemeToggle from '@/components/ui/ThemeToggle';
import { useLocation } from '@/contexts/LocationContext';

interface HeaderProps {
  title?: string;
  showLocation?: boolean;
  showSearch?: boolean;
  transparent?: boolean;
}

const navItems = [
  { href: '/', icon: Home, label: 'Home' },
  { href: '/search', icon: Search, label: 'Search' },
  { href: '/report', icon: Plus, label: 'Report', highlight: true },
  { href: '/notifications', icon: Bell, label: 'Alerts' },
  { href: '/profile', icon: User, label: 'Profile' },
];

export default function Header({ 
  title = 'FINDX', 
  showLocation = true,
  showSearch = false,
  transparent = false,
}: HeaderProps) {
  const pathname = usePathname();
  const { locationName, loading, permissionStatus, requestLocation, refreshLocation } = useLocation();

  const handleLocationClick = async () => {
    if (permissionStatus === 'granted') {
      await refreshLocation();
    } else {
      await requestLocation();
    }
  };

  return (
    <header className={`
      sticky top-0 z-50 w-full
      ${transparent 
        ? 'bg-transparent' 
        : 'bg-white/95 dark:bg-neutral-900/95 backdrop-blur-xl border-b border-neutral-200 dark:border-neutral-800'
      }
    `}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <motion.div
              whileHover={{ scale: 1.02 }}
              className="flex items-center gap-2"
            >
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-primary-600 
                            flex items-center justify-center shadow-sm">
                <svg className="w-5 h-5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="11" cy="11" r="8" />
                  <path d="M21 21l-4.35-4.35" />
                  <path d="M11 8v6M8 11h6" />
                </svg>
              </div>
              <span className="text-xl font-bold text-neutral-900 dark:text-white">
                {title}
              </span>
            </motion.div>
          </Link>

          {/* Desktop Navigation - Hidden on mobile */}
          <nav className="hidden md:flex items-center gap-1">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              const Icon = item.icon;

              if (item.highlight) {
                return (
                  <Link key={item.href} href={item.href}>
                    <motion.div
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="flex items-center gap-2 px-4 py-2 ml-2
                                bg-gradient-to-r from-primary-500 to-primary-600 
                                text-white font-medium rounded-full shadow-md
                                hover:shadow-lg transition-shadow"
                    >
                      <Icon className="w-4 h-4" />
                      <span>{item.label}</span>
                    </motion.div>
                  </Link>
                );
              }

              return (
                <Link key={item.href} href={item.href}>
                  <div className={`
                    flex items-center gap-2 px-4 py-2 rounded-full font-medium text-sm
                    transition-colors
                    ${isActive 
                      ? 'bg-neutral-100 dark:bg-neutral-800 text-primary-600 dark:text-primary-400' 
                      : 'text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                    }
                  `}>
                    <Icon className="w-4 h-4" />
                    <span>{item.label}</span>
                  </div>
                </Link>
              );
            })}
          </nav>

          {/* Right Actions */}
          <div className="flex items-center gap-2">
            {/* Location Button */}
            {showLocation && (
              <motion.button
                onClick={handleLocationClick}
                whileTap={{ scale: 0.98 }}
                className="flex items-center gap-2 px-3 py-2 
                          bg-neutral-100 dark:bg-neutral-800 rounded-full
                          hover:bg-neutral-200 dark:hover:bg-neutral-700 
                          transition-colors text-sm font-medium
                          text-neutral-600 dark:text-neutral-300"
              >
                {loading ? (
                  <Loader2 className="w-4 h-4 text-primary-500 animate-spin" />
                ) : (
                  <MapPin className="w-4 h-4 text-primary-500" />
                )}
                <span className="max-w-[100px] sm:max-w-[150px] truncate hidden xs:inline">
                  {locationName}
                </span>
                {permissionStatus === 'granted' && !loading && (
                  <RefreshCw className="w-3 h-3 text-neutral-400 hidden sm:inline" />
                )}
              </motion.button>
            )}

            {/* Theme Toggle */}
            <ThemeToggle size="sm" />

            {/* Notifications - Mobile only (desktop has it in nav) */}
            <Link href="/notifications" className="md:hidden">
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="relative p-2.5 rounded-full
                          bg-neutral-100 dark:bg-neutral-800
                          hover:bg-neutral-200 dark:hover:bg-neutral-700 
                          transition-colors"
              >
                <Bell className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
                <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full" />
              </motion.div>
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
