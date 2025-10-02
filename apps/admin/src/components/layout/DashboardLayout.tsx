'use client';

import { useState } from 'react';
import { useSession, signOut } from 'next-auth/react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  HomeIcon,
  UsersIcon,
  MusicalNoteIcon,
  ChartBarIcon,
  CreditCardIcon,
  CogIcon,
  Bars3Icon,
  XMarkIcon,
  ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline';

interface DashboardLayoutProps {
  children: React.ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Usuarios', href: '/dashboard/users', icon: UsersIcon },
  { name: 'Artistas', href: '/dashboard/artists', icon: MusicalNoteIcon },
  { name: 'Canciones', href: '/dashboard/songs', icon: MusicalNoteIcon },
  { name: 'Analytics', href: '/dashboard/analytics', icon: ChartBarIcon },
  { name: 'Pagos', href: '/dashboard/payments', icon: CreditCardIcon },
  { name: 'Configuración', href: '/dashboard/settings', icon: CogIcon },
];

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { data: session } = useSession();
  const pathname = usePathname();

  const handleSignOut = () => {
    signOut({ callbackUrl: '/login' });
  };

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Mobile sidebar */}
      <div className={`fixed inset-0 z-50 lg:hidden ${sidebarOpen ? 'block' : 'hidden'}`}>
        <div className="fixed inset-0 bg-warm-600 bg-opacity-75" onClick={() => setSidebarOpen(false)} />
        <div className="fixed inset-y-0 left-0 flex w-64 flex-col bg-white shadow-xl">
          <div className="flex h-16 items-center justify-between px-4">
            <div className="flex items-center">
              <div className="h-8 w-8 bg-vintage-600 rounded-lg flex items-center justify-center">
                <MusicalNoteIcon className="h-5 w-5 text-white" />
              </div>
              <span className="ml-2 text-lg font-vintage font-bold text-warm-900">
                Vintage Music
              </span>
            </div>
            <button
              type="button"
              className="text-warm-400 hover:text-warm-600"
              onClick={() => setSidebarOpen(false)}
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>
          <nav className="flex-1 px-4 py-4 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`sidebar-link ${
                    isActive ? 'sidebar-link-active' : 'sidebar-link-inactive'
                  }`}
                  onClick={() => setSidebarOpen(false)}
                >
                  <item.icon className="mr-3 h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-white border-r border-warm-200">
          <div className="flex h-16 items-center px-4">
            <div className="h-8 w-8 bg-vintage-600 rounded-lg flex items-center justify-center">
              <MusicalNoteIcon className="h-5 w-5 text-white" />
            </div>
            <span className="ml-2 text-lg font-vintage font-bold text-warm-900">
              Vintage Music
            </span>
          </div>
          <nav className="flex-1 px-4 py-4 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`sidebar-link ${
                    isActive ? 'sidebar-link-active' : 'sidebar-link-inactive'
                  }`}
                >
                  <item.icon className="mr-3 h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Top bar */}
        <div className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-warm-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <button
            type="button"
            className="-m-2.5 p-2.5 text-warm-700 lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Bars3Icon className="h-6 w-6" />
          </button>

          <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div className="flex flex-1" />
            <div className="flex items-center gap-x-4 lg:gap-x-6">
              <div className="flex items-center gap-x-2">
                <div className="h-8 w-8 bg-vintage-100 rounded-full flex items-center justify-center">
                  <span className="text-sm font-medium text-vintage-700">
                    {session?.user?.name?.charAt(0)}
                  </span>
                </div>
                <div className="hidden lg:block">
                  <p className="text-sm font-medium text-warm-900">
                    {session?.user?.name}
                  </p>
                  <p className="text-xs text-warm-500">Administrador</p>
                </div>
              </div>
              <button
                onClick={handleSignOut}
                className="text-warm-400 hover:text-warm-600"
                title="Cerrar sesión"
              >
                <ArrowRightOnRectangleIcon className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Page content */}
        <main className="py-6">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}









