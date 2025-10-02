'use client';

import { useState } from 'react';
import { 
  MusicalNoteIcon, 
  UserGroupIcon, 
  ChartBarIcon, 
  PlayIcon,
  TrendingUpIcon,
  ClockIcon,
  HeartIcon,
  EyeIcon
} from '@heroicons/react/24/outline';

export default function DashboardPage() {
  const [activeTab, setActiveTab] = useState('overview');

  const stats = [
    {
      name: 'Usuarios Totales',
      value: '12,543',
      change: '+12%',
      changeType: 'increase',
      icon: UserGroupIcon,
      color: 'blue'
    },
    {
      name: 'Canciones',
      value: '8,432',
      change: '+8%',
      changeType: 'increase',
      icon: MusicalNoteIcon,
      color: 'purple'
    },
    {
      name: 'Reproducciones',
      value: '2.4M',
      change: '+23%',
      changeType: 'increase',
      icon: PlayIcon,
      color: 'green'
    },
    {
      name: 'Artistas',
      value: '1,234',
      change: '+5%',
      changeType: 'increase',
      icon: UserGroupIcon,
      color: 'pink'
    }
  ];

  const recentActivities = [
    { id: 1, type: 'song', title: 'Nueva canción: "Summer Nights"', artist: 'John Doe', time: 'Hace 2 horas' },
    { id: 2, type: 'user', title: 'Nuevo usuario registrado', artist: 'Maria Garcia', time: 'Hace 3 horas' },
    { id: 3, type: 'artist', title: 'Artista verificado', artist: 'The Rockers', time: 'Hace 5 horas' },
    { id: 4, type: 'playlist', title: 'Playlist creada', artist: 'Hits 2024', time: 'Hace 1 día' }
  ];

  const topSongs = [
    { id: 1, title: 'Summer Nights', artist: 'John Doe', plays: '1.2M', trend: 'up' },
    { id: 2, title: 'City Lights', artist: 'Maria Garcia', plays: '890K', trend: 'up' },
    { id: 3, title: 'Ocean Dreams', artist: 'The Rockers', plays: '756K', trend: 'down' },
    { id: 4, title: 'Midnight Jazz', artist: 'Soul Collective', plays: '643K', trend: 'up' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-gray-600 mt-1">Bienvenido al panel de administración de Vintage Music</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm text-gray-500">Última actualización</p>
                <p className="text-sm font-medium text-gray-900">Hace 5 minutos</p>
              </div>
              <div className="w-10 h-10 bg-gradient-to-r from-purple-600 to-blue-600 rounded-full flex items-center justify-center">
                <span className="text-white font-semibold">VM</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {stats.map((stat) => (
            <div key={stat.name} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow duration-200">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                  <div className="flex items-center mt-2">
                    <TrendingUpIcon className="h-4 w-4 text-green-500 mr-1" />
                    <span className="text-sm text-green-600 font-medium">{stat.change}</span>
                  </div>
                </div>
                <div className={`p-3 rounded-xl bg-gradient-to-r ${
                  stat.color === 'blue' ? 'from-blue-500 to-blue-600' :
                  stat.color === 'purple' ? 'from-purple-500 to-purple-600' :
                  stat.color === 'green' ? 'from-green-500 to-green-600' :
                  'from-pink-500 to-pink-600'
                }`}>
                  <stat.icon className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Recent Activities */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Actividad Reciente</h2>
                <button className="text-purple-600 hover:text-purple-700 font-medium text-sm">
                  Ver todo
                </button>
              </div>
              <div className="space-y-4">
                {recentActivities.map((activity) => (
                  <div key={activity.id} className="flex items-center space-x-4 p-4 rounded-xl hover:bg-gray-50 transition-colors duration-200">
                    <div className="flex-shrink-0">
                      <div className="w-10 h-10 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
                        {activity.type === 'song' && <MusicalNoteIcon className="h-5 w-5 text-white" />}
                        {activity.type === 'user' && <UserGroupIcon className="h-5 w-5 text-white" />}
                        {activity.type === 'artist' && <UserGroupIcon className="h-5 w-5 text-white" />}
                        {activity.type === 'playlist' && <PlayIcon className="h-5 w-5 text-white" />}
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">{activity.title}</p>
                      <p className="text-sm text-gray-500 truncate">{activity.artist}</p>
                    </div>
                    <div className="flex-shrink-0 text-right">
                      <p className="text-xs text-gray-500">{activity.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Top Songs */}
          <div>
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Top Canciones</h2>
                <ChartBarIcon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="space-y-4">
                {topSongs.map((song, index) => (
                  <div key={song.id} className="flex items-center space-x-4">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                        {index + 1}
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">{song.title}</p>
                      <p className="text-xs text-gray-500 truncate">{song.artist}</p>
                    </div>
                    <div className="flex-shrink-0 text-right">
                      <p className="text-xs font-medium text-gray-900">{song.plays}</p>
                      <div className="flex items-center">
                        {song.trend === 'up' ? (
                          <TrendingUpIcon className="h-3 w-3 text-green-500" />
                        ) : (
                          <TrendingUpIcon className="h-3 w-3 text-red-500 rotate-180" />
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="mt-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h2 className="text-xl font-bold text-gray-900 mb-6">Acciones Rápidas</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <button className="flex items-center space-x-3 p-4 rounded-xl bg-gradient-to-r from-purple-600 to-purple-700 text-white hover:from-purple-700 hover:to-purple-800 transition-all duration-200 transform hover:scale-105">
                <MusicalNoteIcon className="h-6 w-6" />
                <span className="font-medium">Nueva Canción</span>
              </button>
              <button className="flex items-center space-x-3 p-4 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 text-white hover:from-blue-700 hover:to-blue-800 transition-all duration-200 transform hover:scale-105">
                <UserGroupIcon className="h-6 w-6" />
                <span className="font-medium">Ver Usuarios</span>
              </button>
              <button className="flex items-center space-x-3 p-4 rounded-xl bg-gradient-to-r from-green-600 to-green-700 text-white hover:from-green-700 hover:to-green-800 transition-all duration-200 transform hover:scale-105">
                <ChartBarIcon className="h-6 w-6" />
                <span className="font-medium">Analytics</span>
              </button>
              <button className="flex items-center space-x-3 p-4 rounded-xl bg-gradient-to-r from-indigo-600 to-indigo-700 text-white hover:from-indigo-700 hover:to-indigo-800 transition-all duration-200 transform hover:scale-105">
                <PlayIcon className="h-6 w-6" />
                <span className="font-medium">Playlists</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}