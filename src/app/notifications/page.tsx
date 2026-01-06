'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { ArrowLeft, Bell, CheckCircle, AlertCircle, Sparkles, Settings } from 'lucide-react';
import Link from 'next/link';
import BottomNav from '@/components/layout/BottomNav';
import { formatDistanceToNow } from '@/lib/utils';

// Mock notifications
const MOCK_NOTIFICATIONS = [
  {
    id: '1',
    type: 'match',
    title: 'Potential Match Found!',
    message: 'Your lost iPhone 15 Pro might have been found. Check the match!',
    read: false,
    createdAt: new Date(Date.now() - 30 * 60 * 1000),
    link: '/item/1',
  },
  {
    id: '2',
    type: 'claim',
    title: 'New Claim on Your Report',
    message: 'Someone claims to have found your backpack.',
    read: false,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    link: '/item/2',
  },
  {
    id: '3',
    type: 'success',
    title: 'Item Recovered! 🎉',
    message: 'Your laptop has been marked as recovered. Thank you for using FINDX!',
    read: true,
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    link: '/item/3',
  },
  {
    id: '4',
    type: 'hero',
    title: 'You earned a badge!',
    message: 'Congratulations! You reached Hero Level 2: Finder',
    read: true,
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000),
    link: '/profile',
  },
];

const getNotificationIcon = (type: string) => {
  switch (type) {
    case 'match':
      return <Sparkles className="w-5 h-5 text-purple-500" />;
    case 'claim':
      return <AlertCircle className="w-5 h-5 text-amber-500" />;
    case 'success':
      return <CheckCircle className="w-5 h-5 text-green-500" />;
    case 'hero':
      return <span className="text-lg">🏆</span>;
    default:
      return <Bell className="w-5 h-5 text-primary-500" />;
  }
};

const getNotificationBg = (type: string, read: boolean) => {
  if (read) return 'bg-neutral-50 dark:bg-neutral-800/50';
  switch (type) {
    case 'match':
      return 'bg-purple-50 dark:bg-purple-500/10';
    case 'claim':
      return 'bg-amber-50 dark:bg-amber-500/10';
    case 'success':
      return 'bg-green-50 dark:bg-green-500/10';
    default:
      return 'bg-primary-50 dark:bg-primary-500/10';
  }
};

export default function NotificationsPage() {
  const router = useRouter();
  const notifications = MOCK_NOTIFICATIONS;

  const unreadCount = notifications.filter(n => !n.read).length;

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
          <h1 className="font-semibold text-neutral-900 dark:text-white">Notifications</h1>
          <Link href="/profile/notifications" 
                className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <Settings className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </Link>
        </div>
      </div>

      <div className="px-4 py-6 max-w-lg mx-auto">
        {/* Unread count */}
        {unreadCount > 0 && (
          <div className="mb-4 flex items-center justify-between">
            <span className="text-sm text-neutral-500 dark:text-neutral-400">
              {unreadCount} unread notification{unreadCount > 1 ? 's' : ''}
            </span>
            <button className="text-sm text-primary-600 dark:text-primary-400 font-medium hover:underline">
              Mark all as read
            </button>
          </div>
        )}

        {/* Notifications List */}
        <div className="space-y-3">
          {notifications.length > 0 ? (
            notifications.map((notification, index) => (
              <motion.div
                key={notification.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
              >
                <Link href={notification.link}>
                  <div className={`p-4 rounded-xl border transition-all duration-200 ${
                    notification.read
                      ? 'border-neutral-200 dark:border-neutral-800'
                      : 'border-primary-200 dark:border-primary-800/30'
                  } ${getNotificationBg(notification.type, notification.read)}
                  hover:shadow-sm`}>
                    <div className="flex gap-3">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                        notification.read 
                          ? 'bg-neutral-100 dark:bg-neutral-800' 
                          : 'bg-white dark:bg-neutral-900'
                      }`}>
                        {getNotificationIcon(notification.type)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <h3 className={`font-medium text-sm ${
                            notification.read 
                              ? 'text-neutral-600 dark:text-neutral-400' 
                              : 'text-neutral-900 dark:text-white'
                          }`}>
                            {notification.title}
                          </h3>
                          {!notification.read && (
                            <span className="w-2 h-2 rounded-full bg-primary-500 flex-shrink-0 mt-1.5" />
                          )}
                        </div>
                        <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-0.5 line-clamp-2">
                          {notification.message}
                        </p>
                        <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-2">
                          {formatDistanceToNow(notification.createdAt)}
                        </p>
                      </div>
                    </div>
                  </div>
                </Link>
              </motion.div>
            ))
          ) : (
            <div className="text-center py-16">
              <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 dark:bg-neutral-800 
                            flex items-center justify-center">
                <Bell className="w-8 h-8 text-neutral-300 dark:text-neutral-600" />
              </div>
              <p className="text-neutral-600 dark:text-neutral-400 font-medium">No notifications yet</p>
              <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-1">
                We'll notify you when something happens
              </p>
            </div>
          )}
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
