'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Sun, Moon } from 'lucide-react';
import { useTheme } from '@/contexts/ThemeContext';

interface ThemeToggleProps {
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export default function ThemeToggle({ className = '', size = 'md' }: ThemeToggleProps) {
  const { resolvedTheme, toggleTheme } = useTheme();

  const sizes = {
    sm: { button: 'w-8 h-8', icon: 'w-4 h-4' },
    md: { button: 'w-10 h-10', icon: 'w-5 h-5' },
    lg: { button: 'w-12 h-12', icon: 'w-6 h-6' },
  };

  return (
    <motion.button
      onClick={toggleTheme}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className={`
        ${sizes[size].button}
        relative flex items-center justify-center rounded-full
        bg-neutral-100 dark:bg-neutral-800
        hover:bg-neutral-200 dark:hover:bg-neutral-700
        border border-neutral-200 dark:border-neutral-700
        transition-colors duration-200
        ${className}
      `}
      aria-label={`Switch to ${resolvedTheme === 'light' ? 'dark' : 'light'} mode`}
    >
      <motion.div
        initial={false}
        animate={{
          rotate: resolvedTheme === 'dark' ? 180 : 0,
          scale: 1,
        }}
        transition={{ duration: 0.3, ease: 'easeInOut' }}
      >
        {resolvedTheme === 'light' ? (
          <Sun className={`${sizes[size].icon} text-amber-500`} />
        ) : (
          <Moon className={`${sizes[size].icon} text-blue-400`} />
        )}
      </motion.div>
    </motion.button>
  );
}
