'use client';

import { useAuth } from '@/hooks';

export default function DashboardPage() {
  const { user, logout, isLoggingOut } = useAuth();

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">
                BagTrip Admin
              </h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">
                Bonjour, {user.firstName} {user.lastName}
              </span>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                {user.role}
              </span>
              <button
                onClick={logout}
                disabled={isLoggingOut}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
              >
                {isLoggingOut ? 'Déconnexion...' : 'Déconnexion'}
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="border-4 border-dashed border-gray-200 rounded-lg h-96 flex items-center justify-center">
            <div className="text-center">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Tableau de bord
              </h2>
              <p className="text-gray-600 mb-8">
                Interface d&apos;administration BagTrip configurée avec succès !
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-2xl">
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-medium text-gray-900">Architecture</h3>
                  <p className="text-sm text-gray-500 mt-2">
                    Next.js 15 + TypeScript + React Query
                  </p>
                </div>
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-medium text-gray-900">Authentification</h3>
                  <p className="text-sm text-gray-500 mt-2">
                    JWT + Middleware + Protection des routes
                  </p>
                </div>
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-medium text-gray-900">Qualité</h3>
                  <p className="text-sm text-gray-500 mt-2">
                    ESLint + TypeScript strict + Tests
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}