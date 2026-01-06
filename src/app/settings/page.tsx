'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { 
  ArrowLeft, Bell, Moon, Sun, Globe, Shield, Trash2, 
  Info, LogOut, ChevronRight, Smartphone, MapPin
} from 'lucide-react';
import BottomNav from '@/components/layout/BottomNav';
import { useTheme } from '@/contexts/ThemeContext';

export default function SettingsPage() {
  const router = useRouter();
  const { theme, setTheme } = useTheme();

  type SettingItem = {
    icon: React.ComponentType<{ className?: string }>;
    label: string;
    value?: string;
    href?: string;
    action?: () => void;
  };

  const settingSections: { title: string; items: SettingItem[] }[] = [
    {
      title: 'Appearance',
      items: [
        { 
          icon: theme === 'dark' ? Moon : Sun, 
          label: 'Dark Mode', 
          value: theme === 'dark' ? 'On' : 'Off',
          action: () => setTheme(theme === 'dark' ? 'light' : 'dark')
        },
      ],
    },
    {
      title: 'Notifications',
      items: [
        { icon: Bell, label: 'Push Notifications', value: 'On', href: '/settings/notifications' },
        { icon: MapPin, label: 'Nearby Item Alerts', value: '5 km', href: '/settings/radius' },
      ],
    },
    {
      title: 'Privacy & Security',
      items: [
        { icon: Shield, label: 'Privacy Settings', href: '/settings/privacy' },
        { icon: Globe, label: 'Language', value: 'English', href: '/settings/language' },
      ],
    },
    {
      title: 'About',
      items: [
        { icon: Info, label: 'About FINDX', href: '/about' },
        { icon: Smartphone, label: 'App Version', value: '1.0.0' },
      ],
    },
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
          <h1 className="font-semibold text-neutral-900 dark:text-white">Settings</h1>
          <div className="w-10" />
        </div>
      </div>

      <div className="px-4 py-6 max-w-lg mx-auto space-y-6">
        {settingSections.map((section, sectionIndex) => (
          <motion.div
            key={section.title}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: sectionIndex * 0.05 }}
          >
            <h2 className="text-xs font-semibold text-neutral-500 dark:text-neutral-400 
                         uppercase tracking-wide mb-2 px-1">
              {section.title}
            </h2>
            <div className="card-elevated overflow-hidden">
              {section.items.map((item, itemIndex) => {
                const ItemIcon = item.icon;
                const isLast = itemIndex === section.items.length - 1;
                
                const content = (
                  <div className={`flex items-center gap-4 p-4 
                                  ${!isLast ? 'border-b border-neutral-100 dark:border-neutral-800' : ''}
                                  ${item.action || item.href ? 'hover:bg-neutral-50 dark:hover:bg-neutral-800/50 cursor-pointer' : ''}`}>
                    <div className="w-9 h-9 rounded-lg bg-neutral-100 dark:bg-neutral-800 
                                  flex items-center justify-center">
                      <ItemIcon className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
                    </div>
                    <div className="flex-1">
                      <span className="text-neutral-800 dark:text-neutral-200">
                        {item.label}
                      </span>
                    </div>
                    {item.value && (
                      <span className="text-sm text-neutral-500 dark:text-neutral-400">
                        {item.value}
                      </span>
                    )}
                    {(item.href || item.action) && (
                      <ChevronRight className="w-5 h-5 text-neutral-300 dark:text-neutral-600" />
                    )}
                  </div>
                );

                if (item.action) {
                  return (
                    <button key={item.label} onClick={item.action} className="w-full text-left">
                      {content}
                    </button>
                  );
                }
                
                if (item.href) {
                  return (
                    <div key={item.label} onClick={() => router.push(item.href!)}>
                      {content}
                    </div>
                  );
                }

                return <div key={item.label}>{content}</div>;
              })}
            </div>
          </motion.div>
        ))}

        {/* Danger Zone */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <h2 className="text-xs font-semibold text-red-500 uppercase tracking-wide mb-2 px-1">
            Account
          </h2>
          <div className="card-elevated overflow-hidden">
            <button className="w-full flex items-center gap-4 p-4 
                             hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors">
              <div className="w-9 h-9 rounded-lg bg-red-100 dark:bg-red-500/20 
                            flex items-center justify-center">
                <LogOut className="w-5 h-5 text-red-500" />
              </div>
              <span className="text-red-600 dark:text-red-400 font-medium">
                Sign Out
              </span>
            </button>
            <button className="w-full flex items-center gap-4 p-4 border-t 
                             border-neutral-100 dark:border-neutral-800
                             hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors">
              <div className="w-9 h-9 rounded-lg bg-red-100 dark:bg-red-500/20 
                            flex items-center justify-center">
                <Trash2 className="w-5 h-5 text-red-500" />
              </div>
              <span className="text-red-600 dark:text-red-400">
                Delete Account
              </span>
            </button>
          </div>
        </motion.div>

        {/* Footer */}
        <p className="text-center text-xs text-neutral-400 dark:text-neutral-500 pt-4">
          FINDX v1.0.0 • Made with ❤️ in India
        </p>
      </div>

      <BottomNav />
    </div>
  );
}
