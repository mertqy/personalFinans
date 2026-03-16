'use client';

import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';

// Leaflet ikon hatası düzeltmesi
const icon = L.icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

interface SpendingMapProps {
  transactions: Transaction[];
}

function ChangeView({ center }: { center: [number, number] }) {
  const map = useMap();
  map.setView(center);
  return null;
}

export default function SpendingMap({ transactions }: SpendingMapProps) {
  const [isClient, setIsClient] = useState(false);
  const transactionsWithLocation = transactions.filter(t => t.location);
  
  // Varsayılan merkez: Eğer işlem varsa ilkinin konumu, yoksa İstanbul
  const defaultCenter: [number, number] = transactionsWithLocation.length > 0 
    ? [transactionsWithLocation[0].location!.lat, transactionsWithLocation[0].location!.lng]
    : [41.0082, 28.9784];

  useEffect(() => {
    setIsClient(true);
  }, []);

  if (!isClient) return <div className="h-[400px] w-full bg-gray-800 animate-pulse rounded-3xl" />;

  return (
    <div className="w-full h-full rounded-3xl overflow-hidden border border-gray-700/30 shadow-2xl relative">
      <MapContainer 
        center={defaultCenter} 
        zoom={13} 
        style={{ height: '100%', width: '100%', background: '#111827' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          // Koyu tema için filtre (opsiyonel ama şık durur)
          className="map-tiles"
        />
        
        {transactionsWithLocation.map((t) => (
          <Marker 
            key={t.id} 
            position={[t.location!.lat, t.location!.lng]} 
            icon={icon}
          >
            <Popup>
              <div className="p-2">
                <p className="font-bold text-gray-900">{t.category}</p>
                <p className="text-sm text-gray-600">{t.description}</p>
                <p className={`font-black mt-1 ${t.type === 'income' ? 'text-green-600' : 'text-red-600'}`}>
                   {t.type === 'income' ? '+' : '-'}{formatCurrency(t.amount)}
                </p>
                <p className="text-[10px] text-gray-400 mt-1">
                   {new Date(t.date).toLocaleDateString('tr-TR')}
                </p>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      
      {/* Dark Map Overlay Helper */}
      <style jsx global>{`
        .leaflet-container {
          filter: invert(100%) hue-rotate(180deg) brightness(95%) contrast(90%);
        }
        .leaflet-popup-content-wrapper {
          filter: invert(100%) hue-rotate(-180deg) brightness(105%) contrast(110%);
          background: white !important;
          color: black !important;
          border-radius: 12px;
        }
        .leaflet-popup-tip {
          filter: invert(100%) hue-rotate(-180deg) brightness(105%) contrast(110%);
        }
      `}</style>
    </div>
  );
}
