'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface ItemLocation {
  id: string;
  lat: number;
  lng: number;
  isLost: boolean;
  title: string;
  placeName?: string;
}

export default function HeatmapPage() {
  const [items, setItems] = useState<ItemLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'lost' | 'found'>('all');

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'items'));
      const itemsData = snapshot.docs.map(doc => {
        const data = doc.data();
        let title = data.description || 'Unknown';
        if (title.includes('|||')) {
          title = title.split('|||')[0].trim();
        } else {
          title = title.split('\n')[0];
        }
        return {
          id: doc.id,
          lat: data.latitude || 0,
          lng: data.longitude || 0,
          isLost: data.isLost === true,
          title,
          placeName: data.placeName,
        };
      }).filter(item => item.lat !== 0 && item.lng !== 0);
      
      setItems(itemsData);
    } catch (error) {
      console.error('Error fetching items:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredItems = items.filter(item => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'lost') return item.isLost;
    if (selectedFilter === 'found') return !item.isLost;
    return true;
  });

  // Group items by approximate location (grid cells)
  const getHeatmapData = () => {
    const gridSize = 0.01; // ~1km grid
    const grid: Record<string, { count: number; lost: number; found: number; items: ItemLocation[] }> = {};

    filteredItems.forEach(item => {
      const gridKey = `${Math.floor(item.lat / gridSize)},${Math.floor(item.lng / gridSize)}`;
      if (!grid[gridKey]) {
        grid[gridKey] = { count: 0, lost: 0, found: 0, items: [] };
      }
      grid[gridKey].count++;
      grid[gridKey].items.push(item);
      if (item.isLost) {
        grid[gridKey].lost++;
      } else {
        grid[gridKey].found++;
      }
    });

    return Object.entries(grid).map(([key, data]) => ({
      key,
      ...data,
      lat: parseFloat(key.split(',')[0]) * gridSize + gridSize / 2,
      lng: parseFloat(key.split(',')[1]) * gridSize + gridSize / 2,
    }));
  };

  const heatmapData = getHeatmapData();

  // Get top hotspots
  const topHotspots = [...heatmapData]
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white">📍 Heatmap</h1>
          <p className="text-slate-500 mt-1">Lost & Found hotspots analysis</p>
        </div>
        
        {/* Filter */}
        <div className="flex gap-2">
          {(['all', 'lost', 'found'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setSelectedFilter(f)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
                selectedFilter === f
                  ? f === 'lost' ? 'bg-red-500 text-white' 
                    : f === 'found' ? 'bg-green-500 text-white' 
                    : 'bg-primary text-white'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
              }`}
            >
              {f === 'all' ? '📊 All' : f === 'lost' ? '🔍 Lost' : '✅ Found'}
            </button>
          ))}
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="glass-card rounded-2xl p-6 bg-gradient-to-br from-primary/10 to-primary/5">
          <p className="text-sm text-slate-500">Total Locations</p>
          <p className="text-3xl font-bold text-slate-900 dark:text-white">{heatmapData.length}</p>
        </div>
        <div className="glass-card rounded-2xl p-6 bg-gradient-to-br from-red-500/10 to-red-500/5">
          <p className="text-sm text-slate-500">Lost Items</p>
          <p className="text-3xl font-bold text-red-600">{items.filter(i => i.isLost).length}</p>
        </div>
        <div className="glass-card rounded-2xl p-6 bg-gradient-to-br from-green-500/10 to-green-500/5">
          <p className="text-sm text-slate-500">Found Items</p>
          <p className="text-3xl font-bold text-green-600">{items.filter(i => !i.isLost).length}</p>
        </div>
        <div className="glass-card rounded-2xl p-6 bg-gradient-to-br from-orange-500/10 to-orange-500/5">
          <p className="text-sm text-slate-500">Hotspots (5+ items)</p>
          <p className="text-3xl font-bold text-orange-600">{heatmapData.filter(h => h.count >= 5).length}</p>
        </div>
      </div>

      {/* Top Hotspots Table */}
      <div className="glass-card rounded-2xl overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-700">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">🔥 Top Hotspots</h2>
          <p className="text-sm text-slate-500">Areas with most lost & found activity</p>
        </div>
        <table className="w-full">
          <thead className="bg-slate-50 dark:bg-slate-800">
            <tr>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Rank</th>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Location</th>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Total Items</th>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Lost</th>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Found</th>
              <th className="text-left py-3 px-6 text-sm font-medium text-slate-500">Intensity</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
            {topHotspots.map((hotspot, index) => {
              const intensity = Math.min(hotspot.count / 5, 1);
              const recentItem = hotspot.items[0];
              return (
                <tr key={hotspot.key} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td className="py-4 px-6">
                    <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full font-bold text-sm ${
                      index === 0 ? 'bg-yellow-100 text-yellow-700' :
                      index === 1 ? 'bg-slate-100 text-slate-700' :
                      index === 2 ? 'bg-orange-100 text-orange-700' :
                      'bg-slate-50 text-slate-500'
                    }`}>
                      {index + 1}
                    </span>
                  </td>
                  <td className="py-4 px-6">
                    <p className="font-medium text-slate-900 dark:text-white">
                      {recentItem?.placeName || `Zone ${hotspot.key}`}
                    </p>
                    <p className="text-xs text-slate-500">
                      {hotspot.lat.toFixed(4)}°, {hotspot.lng.toFixed(4)}°
                    </p>
                  </td>
                  <td className="py-4 px-6 font-bold text-slate-900 dark:text-white">
                    {hotspot.count}
                  </td>
                  <td className="py-4 px-6">
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
                      🔍 {hotspot.lost}
                    </span>
                  </td>
                  <td className="py-4 px-6">
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                      ✅ {hotspot.found}
                    </span>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-2 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 rounded-full"
                          style={{ width: `${intensity * 100}%` }}
                        />
                      </div>
                      <span className="text-xs text-slate-500">{(intensity * 100).toFixed(0)}%</span>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        
        {topHotspots.length === 0 && (
          <div className="text-center py-12 text-slate-500">
            No location data available
          </div>
        )}
      </div>

      {/* Visual Grid Heatmap */}
      <div className="glass-card rounded-2xl p-6">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">🗺️ Activity Grid</h2>
        <div className="grid grid-cols-10 gap-1">
          {heatmapData.slice(0, 100).map((cell, idx) => {
            const intensity = Math.min(cell.count / 5, 1);
            return (
              <div
                key={idx}
                className="aspect-square rounded-lg cursor-pointer transition-transform hover:scale-110 relative group"
                style={{
                  backgroundColor: cell.lost > cell.found 
                    ? `rgba(239, 68, 68, ${0.2 + intensity * 0.8})`
                    : `rgba(34, 197, 94, ${0.2 + intensity * 0.8})`,
                }}
                title={`${cell.count} items (${cell.lost} lost, ${cell.found} found)`}
              >
                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-slate-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition whitespace-nowrap pointer-events-none z-10">
                  {cell.count} items
                </div>
              </div>
            );
          })}
        </div>
        <div className="mt-4 flex items-center justify-center gap-4 text-sm text-slate-500">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-red-400"></div>
            <span>More Lost</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-green-400"></div>
            <span>More Found</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-gradient-to-r from-red-200 to-red-600"></div>
            <span>Intensity</span>
          </div>
        </div>
      </div>
    </div>
  );
}
