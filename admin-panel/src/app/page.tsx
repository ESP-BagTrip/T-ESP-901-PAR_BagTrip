'use client'

import Link from 'next/link'
import { useState } from 'react'

export default function Home() {
  const [activeTab, setActiveTab] = useState('features')

  const stats = [
    { label: 'Utilisateurs actifs', value: '12,543', change: '+12%' },
    { label: 'Voyages organisés', value: '8,247', change: '+8%' },
    { label: 'Satisfaction client', value: '4.8/5', change: '+0.2' },
    { label: 'Revenus (€)', value: '245,680', change: '+15%' },
  ]

  const features = [
    {
      icon: '👥',
      title: 'Gestion Utilisateurs',
      description: 'Interface complète pour administrer les comptes, rôles et permissions',
      items: ['CRUD utilisateurs', 'Gestion des rôles', "Logs d'activité", 'Export CSV'],
    },
    {
      icon: '🎫',
      title: 'Gestion Voyages',
      description: 'Supervision des réservations, itinéraires et services',
      items: ['Catalogue voyages', 'Réservations', 'Paiements', 'Rapports'],
    },
    {
      icon: '💬',
      title: 'Support Client',
      description: 'Outils de support et gestion des retours clients',
      items: ['Chat en temps réel', 'Tickets support', 'FAQ dynamique', 'Satisfaction'],
    },
    {
      icon: '📊',
      title: 'Analytics & BI',
      description: 'Tableaux de bord et analyses métier avancées',
      items: ['KPIs temps réel', 'Rapports personnalisés', 'Prédictions IA', 'Export données'],
    },
    {
      icon: '🔐',
      title: 'Sécurité',
      description: "Authentification et contrôle d'accès sécurisés",
      items: ['OAuth 2.0', 'JWT tokens', '2FA', 'Audit de sécurité'],
    },
    {
      icon: '⚙️',
      title: 'Configuration',
      description: 'Paramétrage système et intégrations externes',
      items: ['API management', 'Webhooks', 'Notifications', 'Monitoring'],
    },
  ]

  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <span className="text-2xl font-bold text-blue-600" data-cy="logo">
                  BagTrip
                </span>
                <span className="ml-2 px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
                  Admin
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <Link
                href="/login"
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
                data-cy="login-btn"
              >
                Connexion
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <h1 className="text-5xl md:text-6xl font-bold mb-6" data-cy="hero-title">
              BagTrip Administration
            </h1>
            <p
              className="text-xl md:text-2xl mb-8 max-w-3xl mx-auto text-blue-100"
              data-cy="hero-subtitle"
            >
              Plateforme d&apos;administration complète pour gérer votre écosystème de voyage
            </p>
            <div className="flex justify-center">
              <Link
                href="/login"
                className="bg-white text-blue-600 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors inline-flex items-center"
                data-cy="cta-login"
              >
                <span className="mr-2">🚀</span>
                Accéder à l&apos;administration
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900" data-cy="stats-title">
              Performances en temps réel
            </h2>
            <p className="text-gray-600 mt-4">Données mises à jour automatiquement</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div
                key={index}
                className="bg-white p-6 rounded-xl shadow-lg text-center"
                data-cy={`stat-${index}`}
              >
                <div className="text-3xl font-bold text-blue-600 mb-2">{stat.value}</div>
                <div className="text-gray-600 mb-2">{stat.label}</div>
                <div className="text-sm text-green-600 font-medium">{stat.change} ce mois</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4" data-cy="features-title">
              Interface d&apos;administration complète
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Tous les outils nécessaires pour gérer efficacement votre plateforme de voyage
            </p>
          </div>

          {/* Tab Navigation */}
          <div className="flex justify-center mb-12">
            <div className="bg-gray-100 p-1 rounded-lg">
              <button
                onClick={() => setActiveTab('features')}
                className={`px-6 py-2 rounded-md text-sm font-medium transition-colors ${
                  activeTab === 'features'
                    ? 'bg-white text-blue-600 shadow'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
                data-cy="tab-features"
              >
                Fonctionnalités
              </button>
              <button
                onClick={() => setActiveTab('tech')}
                className={`px-6 py-2 rounded-md text-sm font-medium transition-colors ${
                  activeTab === 'tech'
                    ? 'bg-white text-blue-600 shadow'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
                data-cy="tab-tech"
              >
                Technologies
              </button>
            </div>
          </div>

          {/* Tab Content */}
          {activeTab === 'features' && (
            <div
              className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
              data-cy="features-grid"
            >
              {features.map((feature, index) => (
                <div
                  key={index}
                  className="bg-white p-8 rounded-xl shadow-lg hover:shadow-xl transition-shadow"
                  data-cy={`feature-${index}`}
                >
                  <div className="text-4xl mb-4">{feature.icon}</div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-3">{feature.title}</h3>
                  <p className="text-gray-600 mb-4">{feature.description}</p>
                  <ul className="space-y-2">
                    {feature.items.map((item, idx) => (
                      <li key={idx} className="flex items-center text-sm text-gray-600">
                        <span className="w-1.5 h-1.5 bg-blue-600 rounded-full mr-2"></span>
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          )}

          {activeTab === 'tech' && (
            <div className="bg-gray-50 rounded-2xl p-12" data-cy="tech-stack">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
                <div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-6">Frontend</h3>
                  <div className="space-y-4">
                    {[
                      { name: 'Next.js 15', desc: 'Framework React avec App Router' },
                      { name: 'TypeScript', desc: 'Typage statique et sécurité' },
                      { name: 'TailwindCSS 4', desc: 'Framework CSS utilitaire' },
                      { name: 'React Query', desc: "Gestion d'état serveur" },
                    ].map((tech, idx) => (
                      <div key={idx} className="flex items-start">
                        <div className="w-2 h-2 bg-blue-600 rounded-full mt-2 mr-3"></div>
                        <div>
                          <div className="font-medium text-gray-900">{tech.name}</div>
                          <div className="text-sm text-gray-600">{tech.desc}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-6">Backend & Infra</h3>
                  <div className="space-y-4">
                    {[
                      { name: 'Node.js + Express', desc: 'API REST performante' },
                      { name: 'PostgreSQL', desc: 'Base de données relationnelle' },
                      { name: 'JWT + OAuth', desc: 'Authentification sécurisée' },
                      { name: 'Docker', desc: 'Containerisation et déploiement' },
                    ].map((tech, idx) => (
                      <div key={idx} className="flex items-start">
                        <div className="w-2 h-2 bg-green-600 rounded-full mt-2 mr-3"></div>
                        <div>
                          <div className="font-medium text-gray-900">{tech.name}</div>
                          <div className="text-sm text-gray-600">{tech.desc}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-blue-600">
        <div className="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
          <h2 className="text-4xl font-bold text-white mb-6" data-cy="cta-title">
            Prêt à découvrir BagTrip Admin ?
          </h2>
          <p className="text-xl text-blue-100 mb-8">
            Testez dès maintenant notre interface d&apos;administration avec des données de
            démonstration
          </p>
          <div className="flex justify-center">
            <Link
              href="/login"
              className="bg-white text-blue-600 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors inline-flex items-center justify-center"
              data-cy="final-cta-login"
            >
              <span className="mr-2">🔐</span>
              Se connecter
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="col-span-1 md:col-span-2">
              <div className="flex items-center mb-4">
                <span className="text-2xl font-bold text-blue-400">BagTrip</span>
                <span className="ml-2 px-2 py-1 text-xs bg-blue-900 text-blue-200 rounded">
                  Admin
                </span>
              </div>
              <p className="text-gray-300 mb-4">
                Interface d&apos;administration moderne pour la gestion complète de votre plateforme
                de voyage.
              </p>
              <div className="text-sm text-gray-400">
                © 2024 BagTrip. Développé avec ❤️ et Next.js
              </div>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4" data-cy="footer-links-title">
                Liens utiles
              </h3>
              <ul className="space-y-2 text-gray-300">
                <li>
                  <Link href="/login" className="hover:text-white transition-colors">
                    Connexion
                  </Link>
                </li>
                <li>
                  <a href="#" className="hover:text-white transition-colors">
                    Documentation
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white transition-colors">
                    Support
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4">Contact</h3>
              <ul className="space-y-2 text-gray-300">
                <li>📧 admin@bagtrip.com</li>
                <li>📞 +33 1 23 45 67 89</li>
                <li>🌐 www.bagtrip.com</li>
              </ul>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
