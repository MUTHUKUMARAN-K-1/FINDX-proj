'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

interface Location {
  lat: number;
  lng: number;
  accuracy: number;
}

interface LocationContextType {
  location: Location | null;
  locationName: string;
  loading: boolean;
  error: string | null;
  permissionStatus: 'granted' | 'denied' | 'prompt' | 'unknown';
  requestLocation: () => Promise<void>;
  refreshLocation: () => Promise<void>;
}

const LocationContext = createContext<LocationContextType | undefined>(undefined);

// Reverse geocoding to get location name
async function getLocationName(lat: number, lng: number): Promise<string> {
  try {
    // Using free Nominatim API for reverse geocoding
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=16&addressdetails=1`,
      { headers: { 'User-Agent': 'FINDX-App' } }
    );
    
    if (!response.ok) throw new Error('Geocoding failed');
    
    const data = await response.json();
    
    // Extract meaningful location parts
    const address = data.address;
    const parts = [];
    
    if (address.neighbourhood) parts.push(address.neighbourhood);
    else if (address.suburb) parts.push(address.suburb);
    else if (address.village) parts.push(address.village);
    
    if (address.city) parts.push(address.city);
    else if (address.town) parts.push(address.town);
    else if (address.state_district) parts.push(address.state_district);
    
    return parts.slice(0, 2).join(', ') || data.display_name?.split(',').slice(0, 2).join(',') || 'Unknown location';
  } catch (error) {
    console.error('Reverse geocoding error:', error);
    return 'Location detected';
  }
}

export function LocationProvider({ children }: { children: React.ReactNode }) {
  const [location, setLocation] = useState<Location | null>(null);
  const [locationName, setLocationName] = useState<string>('Detecting...');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [permissionStatus, setPermissionStatus] = useState<'granted' | 'denied' | 'prompt' | 'unknown'>('unknown');

  // Check permission status
  const checkPermission = useCallback(async () => {
    if (!('permissions' in navigator)) {
      setPermissionStatus('unknown');
      return;
    }
    
    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });
      setPermissionStatus(result.state as 'granted' | 'denied' | 'prompt');
      
      result.addEventListener('change', () => {
        setPermissionStatus(result.state as 'granted' | 'denied' | 'prompt');
      });
    } catch {
      setPermissionStatus('unknown');
    }
  }, []);

  // Request and get location
  const requestLocation = useCallback(async (): Promise<void> => {
    if (!('geolocation' in navigator)) {
      setError('Geolocation is not supported by your browser');
      setLocationName('Not supported');
      return;
    }

    setLoading(true);
    setError(null);

    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const newLocation = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
            accuracy: position.coords.accuracy,
          };
          
          setLocation(newLocation);
          setPermissionStatus('granted');
          
          // Get location name
          const name = await getLocationName(newLocation.lat, newLocation.lng);
          setLocationName(name);
          
          // Save to localStorage
          localStorage.setItem('findx-location', JSON.stringify(newLocation));
          localStorage.setItem('findx-location-name', name);
          
          setLoading(false);
          resolve();
        },
        (err) => {
          console.error('Geolocation error:', err);
          
          switch (err.code) {
            case err.PERMISSION_DENIED:
              setError('Location permission denied');
              setLocationName('Permission denied');
              setPermissionStatus('denied');
              break;
            case err.POSITION_UNAVAILABLE:
              setError('Location unavailable');
              setLocationName('Unavailable');
              break;
            case err.TIMEOUT:
              setError('Location request timed out');
              setLocationName('Timeout');
              break;
            default:
              setError('Unknown error getting location');
              setLocationName('Error');
          }
          
          setLoading(false);
          resolve();
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 60000, // Cache for 1 minute
        }
      );
    });
  }, []);

  const refreshLocation = useCallback(async () => {
    await requestLocation();
  }, [requestLocation]);

  // Initialize on mount
  useEffect(() => {
    checkPermission();
    
    // Try to load cached location first
    const cached = localStorage.getItem('findx-location');
    const cachedName = localStorage.getItem('findx-location-name');
    
    if (cached && cachedName) {
      try {
        setLocation(JSON.parse(cached));
        setLocationName(cachedName);
      } catch {
        // Invalid cached data
      }
    }
    
    // Request fresh location if permission was granted before
    if (navigator.permissions) {
      navigator.permissions.query({ name: 'geolocation' }).then((result) => {
        if (result.state === 'granted') {
          requestLocation();
        }
      });
    }
  }, [checkPermission, requestLocation]);

  return (
    <LocationContext.Provider 
      value={{ 
        location, 
        locationName, 
        loading, 
        error, 
        permissionStatus,
        requestLocation, 
        refreshLocation 
      }}
    >
      {children}
    </LocationContext.Provider>
  );
}

export function useLocation() {
  const context = useContext(LocationContext);
  if (context === undefined) {
    throw new Error('useLocation must be used within a LocationProvider');
  }
  return context;
}
