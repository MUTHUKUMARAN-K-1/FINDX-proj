'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs, orderBy, query, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface Item {
  id: string;
  description: string;
  isLost: boolean;
  category?: string;
  placeName?: string;
  imageUrl?: string;
  status?: string;
  timestamp?: Timestamp;
}

export default function ItemsPage() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'lost' | 'found'>('all');

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      const q = query(collection(db, 'items'), orderBy('timestamp', 'desc'));
      const snapshot = await getDocs(q);
      const itemsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as Item[];
      setItems(itemsData);
    } catch (error) {
      console.error('Error fetching items:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredItems = items.filter(item => {
    if (filter === 'all') return true;
    if (filter === 'lost') return item.isLost === true;
    if (filter === 'found') return item.isLost === false;
    return true;
  });

  const parseTitle = (description: string) => {
    if (description.includes('|||')) {
      return description.split('|||')[0].trim();
    }
    return description.split('\n')[0];
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Items</h1>
          <p className="text-slate-500 mt-1">{items.length} total items</p>
        </div>
        
        {/* Filter */}
        <div className="flex gap-2">
          {(['all', 'lost', 'found'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
                filter === f
                  ? 'bg-primary text-white'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
              }`}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Items Table */}
      <div className="glass-card rounded-2xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-slate-50 dark:bg-slate-800">
            <tr>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Image</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Title</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Type</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Category</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Location</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Status</th>
              <th className="text-left py-4 px-6 text-sm font-medium text-slate-500">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
            {filteredItems.map((item) => (
              <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                <td className="py-4 px-6">
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={parseTitle(item.description)}
                      className="w-12 h-12 rounded-lg object-cover"
                    />
                  ) : (
                    <div className="w-12 h-12 rounded-lg bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
                      <span className="text-lg">📦</span>
                    </div>
                  )}
                </td>
                <td className="py-4 px-6">
                  <p className="font-medium text-slate-900 dark:text-white truncate max-w-xs">
                    {parseTitle(item.description)}
                  </p>
                </td>
                <td className="py-4 px-6">
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                      item.isLost
                        ? 'bg-red-100 text-red-700'
                        : 'bg-green-100 text-green-700'
                    }`}
                  >
                    {item.isLost ? '🔍 Lost' : '✅ Found'}
                  </span>
                </td>
                <td className="py-4 px-6 text-slate-600 dark:text-slate-400">
                  {item.category || 'Other'}
                </td>
                <td className="py-4 px-6 text-slate-600 dark:text-slate-400 truncate max-w-xs">
                  {item.placeName || 'Unknown'}
                </td>
                <td className="py-4 px-6">
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                      item.status === 'returned'
                        ? 'bg-purple-100 text-purple-700'
                        : 'bg-blue-100 text-blue-700'
                    }`}
                  >
                    {item.status || 'Active'}
                  </span>
                </td>
                <td className="py-4 px-6 text-slate-500 text-sm">
                  {item.timestamp?.toDate?.()?.toLocaleDateString() || 'N/A'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        
        {filteredItems.length === 0 && (
          <div className="text-center py-12 text-slate-500">
            No items found
          </div>
        )}
      </div>
    </div>
  );
}
