'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs, query, where, orderBy, limit, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';
import { Line, Doughnut, Bar } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

interface Stats {
  totalItems: number;
  lostItems: number;
  foundItems: number;
  returnedItems: number;
  totalUsers: number;
  activeToday: number;
  categoryCounts: Record<string, number>;
  dailyReports: { date: string; count: number }[];
}

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      console.log('Fetching stats...');
      console.log('DB instance:', db);
      
      if (!db) {
        console.error('Firebase DB not initialized!');
        setLoading(false);
        return;
      }

      // Fetch items
      console.log('Fetching items...');
      const itemsSnapshot = await getDocs(collection(db, 'items'));
      console.log('Items fetched:', itemsSnapshot.size);
      const items = itemsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      
      // Fetch users
      console.log('Fetching users...');
      const usersSnapshot = await getDocs(collection(db, 'users'));
      console.log('Users fetched:', usersSnapshot.size);
      const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // Calculate stats
      const lostItems = items.filter((i: any) => i.isLost === true).length;
      const foundItems = items.filter((i: any) => i.isLost === false).length;
      const returnedItems = items.filter((i: any) => i.status === 'returned').length;

      // Category counts
      const categoryCounts: Record<string, number> = {};
      items.forEach((item: any) => {
        const category = item.category || 'Other';
        categoryCounts[category] = (categoryCounts[category] || 0) + 1;
      });

      // Daily reports (last 7 days)
      const last7Days = Array.from({ length: 7 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (6 - i));
        return date.toISOString().split('T')[0];
      });

      const dailyReports = last7Days.map(date => {
        const count = items.filter((item: any) => {
          const itemDate = item.timestamp?.toDate?.()?.toISOString?.()?.split('T')[0] || '';
          return itemDate === date;
        }).length;
        return { date, count };
      });

      // Active today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const activeToday = users.filter((u: any) => {
        const lastActive = u.lastActive?.toDate?.();
        return lastActive && lastActive >= today;
      }).length;

      console.log('Stats calculated:', { totalItems: items.length, lostItems, foundItems, totalUsers: users.length });

      setStats({
        totalItems: items.length,
        lostItems,
        foundItems,
        returnedItems,
        totalUsers: users.length,
        activeToday,
        categoryCounts,
        dailyReports,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
      // Show error in alert for debugging
      alert('Error fetching data: ' + (error as Error).message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  const lineChartData = {
    labels: stats?.dailyReports.map(d => {
      const date = new Date(d.date);
      return date.toLocaleDateString('en-US', { weekday: 'short' });
    }) || [],
    datasets: [
      {
        label: 'Reports',
        data: stats?.dailyReports.map(d => d.count) || [],
        fill: true,
        borderColor: '#6366F1',
        backgroundColor: 'rgba(99, 102, 241, 0.1)',
        tension: 0.4,
      },
    ],
  };

  const doughnutData = {
    labels: Object.keys(stats?.categoryCounts || {}),
    datasets: [
      {
        data: Object.values(stats?.categoryCounts || {}),
        backgroundColor: [
          '#6366F1',
          '#A855F7',
          '#22C55E',
          '#F59E0B',
          '#EF4444',
          '#06B6D4',
          '#EC4899',
        ],
        borderWidth: 0,
      },
    ],
  };

  const barChartData = {
    labels: ['Lost', 'Found', 'Returned'],
    datasets: [
      {
        label: 'Items',
        data: [stats?.lostItems || 0, stats?.foundItems || 0, stats?.returnedItems || 0],
        backgroundColor: ['#EF4444', '#22C55E', '#6366F1'],
        borderRadius: 8,
      },
    ],
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Analytics Dashboard</h1>
          <p className="text-slate-500 mt-1">Real-time insights for FindX platform</p>
        </div>
        <button
          onClick={fetchStats}
          className="px-4 py-2 bg-primary text-white rounded-xl hover:bg-primary/90 transition flex items-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Items"
          value={stats?.totalItems || 0}
          icon="📦"
          color="primary"
          change="+12% this week"
        />
        <StatCard
          title="Lost Items"
          value={stats?.lostItems || 0}
          icon="🔍"
          color="danger"
          change="Active searches"
        />
        <StatCard
          title="Found Items"
          value={stats?.foundItems || 0}
          icon="✅"
          color="success"
          change="Waiting for owners"
        />
        <StatCard
          title="Returned"
          value={stats?.returnedItems || 0}
          icon="🎉"
          color="purple"
          change="Successfully reunited"
        />
      </div>

      {/* User Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <StatCard
          title="Total Users"
          value={stats?.totalUsers || 0}
          icon="👥"
          color="primary"
          change="Registered users"
        />
        <StatCard
          title="Active Today"
          value={stats?.activeToday || 0}
          icon="🟢"
          color="success"
          change="Online now"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Line Chart - Daily Reports */}
        <div className="glass-card rounded-2xl p-6">
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            📈 Reports (Last 7 Days)
          </h3>
          <Line
            data={lineChartData}
            options={{
              responsive: true,
              plugins: { legend: { display: false } },
              scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.05)' } },
                x: { grid: { display: false } },
              },
            }}
          />
        </div>

        {/* Doughnut - Categories */}
        <div className="glass-card rounded-2xl p-6">
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            📊 Items by Category
          </h3>
          <div className="h-64 flex items-center justify-center">
            <Doughnut
              data={doughnutData}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: { position: 'right' },
                },
              }}
            />
          </div>
        </div>
      </div>

      {/* Bar Chart - Status */}
      <div className="glass-card rounded-2xl p-6">
        <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
          📋 Item Status Overview
        </h3>
        <div className="h-64">
          <Bar
            data={barChartData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: { legend: { display: false } },
              scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.05)' } },
                x: { grid: { display: false } },
              },
            }}
          />
        </div>
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  icon,
  color,
  change,
}: {
  title: string;
  value: number;
  icon: string;
  color: 'primary' | 'success' | 'danger' | 'warning' | 'purple';
  change: string;
}) {
  const colorClasses = {
    primary: 'from-primary/10 to-primary/5 border-primary/20',
    success: 'from-success/10 to-success/5 border-success/20',
    danger: 'from-danger/10 to-danger/5 border-danger/20',
    warning: 'from-warning/10 to-warning/5 border-warning/20',
    purple: 'from-secondary/10 to-secondary/5 border-secondary/20',
  };

  return (
    <div className={`glass-card rounded-2xl p-6 bg-gradient-to-br ${colorClasses[color]} border`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-slate-500 dark:text-slate-400">{title}</p>
          <p className="text-3xl font-bold text-slate-900 dark:text-white mt-2">{value}</p>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">{change}</p>
        </div>
        <span className="text-3xl">{icon}</span>
      </div>
    </div>
  );
}
