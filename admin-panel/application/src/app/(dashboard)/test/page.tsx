'use client'

import { useAuth } from '@/hooks'
import {
  bookingIntentsService,
  flightsService,
  hotelsService,
  paymentsService,
  travelersService,
  tripsService,
} from '@/services'
import type {
  BookingIntent,
  BookingIntentBookRequestFlight,
  BookingIntentBookRequestHotel,
  BookingIntentCreateRequest,
  FlightSearchCreateRequest,
  FlightSearchResponse,
  HotelSearchCreateRequest,
  HotelSearchResponse,
  PaymentAuthorizeResponse,
  Traveler,
  TravelerCreateRequest,
  Trip,
  TripCreateRequest,
} from '@/types'
import { loadStripe } from '@stripe/stripe-js'
import { useEffect, useRef, useState } from 'react'

export default function TestPage() {
  const { user, isAuthenticated } = useAuth()
  const [activeSection, setActiveSection] = useState<string>('auth')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [response, setResponse] = useState<Record<string, unknown> | null>(null)

  // State for each step
  const [trip, setTrip] = useState<Trip | null>(null)
  const [traveler, setTraveler] = useState<Traveler | null>(null)
  const [flightSearch, setFlightSearch] = useState<FlightSearchResponse | null>(null)
  const [selectedFlightOfferId, setSelectedFlightOfferId] = useState<string | null>(null)
  const [hotelSearch, setHotelSearch] = useState<HotelSearchResponse | null>(null)
  const [selectedHotelOfferId, setSelectedHotelOfferId] = useState<string | null>(null)
  const [bookingIntent, setBookingIntent] = useState<BookingIntent | null>(null)
  const [paymentAuth, setPaymentAuth] = useState<PaymentAuthorizeResponse | null>(null)
  const [polling, setPolling] = useState(false)
  const [pollingError, setPollingError] = useState<string | null>(null)
  const [showFlightOffers, setShowFlightOffers] = useState(true)
  const [showHotelOffers, setShowHotelOffers] = useState(true)
  const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null)
  const stripeRef = useRef<Awaited<ReturnType<typeof loadStripe>> | null>(null)

  // Initialize Stripe
  useEffect(() => {
    const initStripe = async () => {
      const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
      if (publishableKey) {
        stripeRef.current = await loadStripe(publishableKey)
      }
    }
    initStripe()
  }, [])

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current)
      }
    }
  }, [])

  const pollBookingIntentStatus = async (intentId: string, maxAttempts = 20) => {
    let attempts = 0
    setPolling(true)
    setPollingError(null)

    const poll = async () => {
      try {
        attempts++
        const updatedIntent = await bookingIntentsService.getBookingIntent(intentId)
        setBookingIntent(updatedIntent)

        if (updatedIntent.status === 'AUTHORIZED') {
          setPolling(false)
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          return
        }

        if (attempts >= maxAttempts) {
          setPolling(false)
          setPollingError("Timeout: Le statut n'a pas été mis à jour à temps")
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          return
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Erreur lors du polling'
        setPollingError(errorMessage)
        setPolling(false)
        if (pollingIntervalRef.current) {
          clearInterval(pollingIntervalRef.current)
          pollingIntervalRef.current = null
        }
      }
    }

    // Poll immediately, then every 2 seconds
    await poll()
    pollingIntervalRef.current = setInterval(poll, 2000)
  }

  const handleConfirmPayment = async () => {
    if (!bookingIntent) {
      setError('Booking intent manquant')
      return
    }

    setLoading(true)
    setError(null)
    setPollingError(null)

    try {
      // For POC: Use backend endpoint to confirm payment with test card
      // This will confirm the payment and update status to AUTHORIZED
      await handleApiCall(() => paymentsService.confirmPaymentTest(bookingIntent.id), 'payment')

      // Refresh booking intent to get updated status
      const updatedIntent = await bookingIntentsService.getBookingIntent(bookingIntent.id)
      setBookingIntent(updatedIntent)

      // If status is not yet AUTHORIZED, start polling (webhook might be delayed)
      if (updatedIntent.status !== 'AUTHORIZED') {
        await pollBookingIntentStatus(bookingIntent.id)
      }
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : 'Erreur lors de la confirmation du paiement'
      setError(errorMessage)
      setLoading(false)
    }
  }

  const handleApiCall = async (fn: () => Promise<unknown>, section?: string) => {
    setLoading(true)
    setError(null)
    setResponse(null)
    try {
      const result = await fn()
      setResponse(result as Record<string, unknown>)
      if (section) {
        setActiveSection(section)
      }
      return result
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Une erreur est survenue'
      setError(errorMessage)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTrip = async () => {
    const data: TripCreateRequest = {
      title: 'Paris to Rome',
      originIata: 'PAR',
      destinationIata: 'ROM',
      startDate: '2026-01-10',
      endDate: '2026-01-13',
    }
    const result = await handleApiCall(() => tripsService.createTrip(data), 'trip')
    setTrip(result as Trip)
  }

  const handleCreateTraveler = async () => {
    if (!trip) {
      setError("Veuillez d'abord créer un trip")
      return
    }
    const data: TravelerCreateRequest = {
      amadeusTravelerRef: '1',
      travelerType: 'ADULT',
      firstName: 'John',
      lastName: 'Doe',
      dateOfBirth: '1990-05-15',
      gender: 'MALE',
      documents: [
        {
          documentType: 'PASSPORT',
          number: '12AB34567',
          expiryDate: '2030-01-01',
          issuanceCountry: 'FR',
          nationality: 'FR',
        },
      ],
      contacts: {
        emailAddress: user?.email || 'test@example.com',
        phoneNumber: '+33612345678',
      },
    }
    const result = await handleApiCall(
      () => travelersService.createTraveler(trip.id, data),
      'traveler'
    )
    setTraveler(result as Traveler)
  }

  const handleSearchFlights = async () => {
    if (!trip) {
      setError("Veuillez d'abord créer un trip")
      return
    }
    const data: FlightSearchCreateRequest = {
      originIata: 'PAR',
      destinationIata: 'ROM',
      departureDate: '2026-01-10',
      returnDate: '2026-01-13',
      adults: 1,
      currency: 'EUR',
      travelClass: 'ECONOMY',
    }
    const result = await handleApiCall(() => flightsService.searchFlights(trip.id, data), 'flight')
    setFlightSearch(result as FlightSearchResponse)
  }

  const handleSearchHotels = async () => {
    if (!trip) {
      setError("Veuillez d'abord créer un trip")
      return
    }
    const data: HotelSearchCreateRequest = {
      cityCode: 'ROM',
      checkIn: '2026-01-10',
      checkOut: '2026-01-13',
      adults: 1,
      roomQty: 1,
      currency: 'EUR',
    }
    const result = await handleApiCall(() => hotelsService.searchHotels(trip.id, data), 'hotel')
    setHotelSearch(result as HotelSearchResponse)
  }

  const handleCreateBookingIntent = async (type: 'flight' | 'hotel') => {
    if (!trip) {
      setError("Veuillez d'abord créer un trip")
      return
    }
    const data: BookingIntentCreateRequest = {
      type,
      flightOfferId: type === 'flight' && selectedFlightOfferId ? selectedFlightOfferId : undefined,
      hotelOfferId: type === 'hotel' && selectedHotelOfferId ? selectedHotelOfferId : undefined,
    }
    const result = await handleApiCall(
      () => bookingIntentsService.createBookingIntent(trip.id, data),
      'booking'
    )
    setBookingIntent(result as BookingIntent)
  }

  const handleAuthorizePayment = async () => {
    if (!bookingIntent) {
      setError("Veuillez d'abord créer un booking intent")
      return
    }
    const result = await handleApiCall(
      () =>
        paymentsService.authorizePayment(bookingIntent.id, {
          returnUrl: window.location.href,
        }),
      'payment'
    )
    setPaymentAuth(result as PaymentAuthorizeResponse)
  }

  const handleBookFlight = async () => {
    if (!bookingIntent || !traveler) {
      setError("Veuillez d'abord créer un booking intent et un traveler")
      return
    }
    const data: BookingIntentBookRequestFlight = {
      travelerIds: [traveler.id],
      contacts: [
        {
          emailAddress: user?.email || 'test@example.com',
        },
      ],
    }
    const result = await handleApiCall(
      () => bookingIntentsService.bookFlight(bookingIntent.id, data),
      'book'
    )
    // Update booking intent status after booking
    if (result && bookingIntent) {
      const updatedIntent = await bookingIntentsService.getBookingIntent(bookingIntent.id)
      setBookingIntent(updatedIntent)
    }
  }

  const handleBookHotel = async () => {
    if (!bookingIntent) {
      setError("Veuillez d'abord créer un booking intent")
      return
    }
    const data: BookingIntentBookRequestHotel = {
      guests: [
        {
          name: {
            firstName: 'John',
            lastName: 'Doe',
          },
          contact: {
            email: user?.email || 'test@example.com',
          },
        },
      ],
      roomAssociations: [
        {
          guestReferences: ['1'],
          hotelOfferId: selectedHotelOfferId || '',
        },
      ],
    }
    const result = await handleApiCall(
      () => bookingIntentsService.bookHotel(bookingIntent.id, data),
      'book'
    )
    // Update booking intent status after booking
    if (result && bookingIntent) {
      const updatedIntent = await bookingIntentsService.getBookingIntent(bookingIntent.id)
      setBookingIntent(updatedIntent)
    }
  }

  const handleCapturePayment = async () => {
    if (!bookingIntent) {
      setError("Veuillez d'abord créer un booking intent")
      return
    }
    const result = await handleApiCall(
      () => paymentsService.capturePayment(bookingIntent.id),
      'capture'
    )
    // Update booking intent status after capture
    if (result && bookingIntent) {
      const updatedIntent = await bookingIntentsService.getBookingIntent(bookingIntent.id)
      setBookingIntent(updatedIntent)
    }
  }

  const Section = ({
    id,
    title,
    children,
  }: {
    id: string
    title: string
    children: React.ReactNode
  }) => (
    <div className="mb-6 border rounded-lg">
      <button
        onClick={() => setActiveSection(activeSection === id ? '' : id)}
        className="w-full px-4 py-3 bg-gray-50 hover:bg-gray-100 flex justify-between items-center"
      >
        <h3 className="text-lg font-semibold">{title}</h3>
        <span>{activeSection === id ? '−' : '+'}</span>
      </button>
      {activeSection === id && <div className="p-4">{children}</div>}
    </div>
  )

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Authentification requise</h2>
          <p className="text-gray-600">Veuillez vous connecter pour accéder à cette page</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Test View - Booking Flow</h1>
        <p className="text-gray-600 mb-8">
          Interface de test basée sur TESTING_PLAN.md pour tester le flux de réservation complet
        </p>

        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-700">{error}</p>
          </div>
        )}

        {response && (
          <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
            <h4 className="font-semibold mb-2">Réponse API:</h4>
            <pre className="text-xs overflow-auto max-h-64">
              {JSON.stringify(response, null, 2)}
            </pre>
          </div>
        )}

        <Section id="auth" title="1. Authentication">
          <div className="space-y-4">
            <p className="text-sm text-gray-600">
              Utilisateur connecté: <strong>{user?.email}</strong>
            </p>
            <p className="text-sm text-gray-600">ID: {user?.id}</p>
          </div>
        </Section>

        <Section id="trip" title="2. Create Trip">
          <div className="space-y-4">
            {trip ? (
              <div className="p-4 bg-blue-50 rounded-lg">
                <p className="font-semibold">Trip créé:</p>
                <p className="text-sm">ID: {trip.id}</p>
                <p className="text-sm">Title: {trip.title}</p>
                <p className="text-sm">
                  {trip.originIata} → {trip.destinationIata}
                </p>
              </div>
            ) : (
              <button
                onClick={handleCreateTrip}
                disabled={loading}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {loading ? 'Création...' : 'Créer un Trip (Paris → Rome)'}
              </button>
            )}
          </div>
        </Section>

        <Section id="traveler" title="3. Add Traveler">
          <div className="space-y-4">
            {traveler ? (
              <div className="p-4 bg-blue-50 rounded-lg">
                <p className="font-semibold">Traveler créé:</p>
                <p className="text-sm">ID: {traveler.id}</p>
                <p className="text-sm">
                  {traveler.firstName} {traveler.lastName}
                </p>
              </div>
            ) : (
              <button
                onClick={handleCreateTraveler}
                disabled={loading || !trip}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {loading ? 'Création...' : 'Ajouter un Traveler'}
              </button>
            )}
          </div>
        </Section>

        <Section id="flight" title="4. Flight Booking Flow">
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold">4.1 Search Flights</h4>
                {flightSearch && (
                  <button
                    onClick={() => setShowFlightOffers(!showFlightOffers)}
                    className="text-xs text-blue-600 hover:text-blue-800"
                  >
                    {showFlightOffers ? 'Masquer' : 'Afficher'} les offres
                  </button>
                )}
              </div>
              {flightSearch ? (
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm mb-2">Search ID: {flightSearch.searchId}</p>
                  <p className="text-sm mb-2">
                    Offres trouvées: {flightSearch.offers.length}
                    {selectedFlightOfferId && (
                      <span className="ml-2 text-green-600">• Offre sélectionnée</span>
                    )}
                  </p>
                  {showFlightOffers && (
                    <div className="space-y-2 max-h-64 overflow-y-auto mt-2">
                      {flightSearch.offers.map(offer => (
                        <div
                          key={offer.id}
                          className="p-2 border rounded cursor-pointer hover:bg-blue-50"
                          onClick={() => setSelectedFlightOfferId(offer.id)}
                        >
                          <p className="text-sm font-semibold">
                            {offer.grandTotal} {offer.currency}
                          </p>
                          <p className="text-xs text-gray-600">ID: {offer.id}</p>
                          {selectedFlightOfferId === offer.id && (
                            <p className="text-xs text-blue-600">✓ Sélectionné</p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <button
                  onClick={handleSearchFlights}
                  disabled={loading || !trip}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                >
                  {loading ? 'Recherche...' : 'Rechercher des vols'}
                </button>
              )}
            </div>

            <div>
              <h4 className="font-semibold mb-2">4.3 Create Booking Intent</h4>
              <button
                onClick={() => handleCreateBookingIntent('flight')}
                disabled={loading || !selectedFlightOfferId}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {loading ? 'Création...' : 'Créer Booking Intent (Flight)'}
              </button>
            </div>

            {bookingIntent && bookingIntent.type === 'flight' && (
              <>
                <div>
                  <h4 className="font-semibold mb-2">4.4 Authorize Payment</h4>
                  <p className="text-sm text-gray-600 mb-2">
                    Status: <strong>{bookingIntent.status}</strong>
                  </p>
                  {paymentAuth ? (
                    <div className="p-4 bg-yellow-50 rounded-lg space-y-3">
                      <div>
                        <p className="text-sm font-semibold">
                          Payment Intent ID: {paymentAuth.stripePaymentIntentId}
                        </p>
                        <p className="text-xs text-gray-600 mt-1">Status: {paymentAuth.status}</p>
                      </div>
                      {polling && (
                        <div className="p-2 bg-blue-50 rounded border border-blue-200">
                          <div className="flex items-center">
                            <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-blue-600 mr-2"></div>
                            <p className="text-xs text-blue-700">
                              Attente de l&apos;autorisation du paiement...
                            </p>
                          </div>
                        </div>
                      )}
                      {pollingError && (
                        <div className="p-2 bg-red-50 rounded border border-red-200">
                          <p className="text-xs text-red-700">{pollingError}</p>
                        </div>
                      )}
                      {bookingIntent?.status === 'AUTHORIZED' ? (
                        <div className="p-2 bg-green-50 rounded border border-green-200">
                          <p className="text-xs text-green-700 font-semibold">
                            ✓ Paiement autorisé! Vous pouvez maintenant réserver le vol.
                          </p>
                        </div>
                      ) : (
                        <button
                          onClick={handleConfirmPayment}
                          disabled={loading || polling || bookingIntent?.status === 'AUTHORIZED'}
                          className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 text-sm"
                        >
                          {loading || polling
                            ? 'Confirmation...'
                            : 'Confirmer le paiement (Test Card)'}
                        </button>
                      )}
                    </div>
                  ) : (
                    <button
                      onClick={handleAuthorizePayment}
                      disabled={loading || bookingIntent.status !== 'INIT'}
                      className="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 disabled:opacity-50"
                    >
                      {loading ? 'Autorisation...' : 'Autoriser le paiement'}
                    </button>
                  )}
                </div>

                <div>
                  <h4 className="font-semibold mb-2">4.6 Book Flight</h4>
                  <button
                    onClick={handleBookFlight}
                    disabled={loading || bookingIntent.status !== 'AUTHORIZED'}
                    className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                  >
                    {loading ? 'Réservation...' : 'Réserver le vol'}
                  </button>
                </div>

                <div>
                  <h4 className="font-semibold mb-2">4.7 Capture Payment</h4>
                  <button
                    onClick={handleCapturePayment}
                    disabled={loading || bookingIntent.status !== 'BOOKED'}
                    className="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 disabled:opacity-50"
                  >
                    {loading ? 'Capture...' : 'Capturer le paiement'}
                  </button>
                </div>
              </>
            )}
          </div>
        </Section>

        <Section id="hotel" title="5. Hotel Booking Flow">
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold">5.1 Search Hotels</h4>
                {hotelSearch && (
                  <button
                    onClick={() => setShowHotelOffers(!showHotelOffers)}
                    className="text-xs text-blue-600 hover:text-blue-800"
                  >
                    {showHotelOffers ? 'Masquer' : 'Afficher'} les offres
                  </button>
                )}
              </div>
              {hotelSearch ? (
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm mb-2">Search ID: {hotelSearch.searchId}</p>
                  <p className="text-sm mb-2">
                    Offres trouvées: {hotelSearch.offers.length}
                    {selectedHotelOfferId && (
                      <span className="ml-2 text-green-600">• Offre sélectionnée</span>
                    )}
                  </p>
                  {showHotelOffers && (
                    <div className="space-y-2 max-h-64 overflow-y-auto mt-2">
                      {hotelSearch.offers.map(offer => (
                        <div
                          key={offer.id}
                          className="p-2 border rounded cursor-pointer hover:bg-blue-50"
                          onClick={() => setSelectedHotelOfferId(offer.id)}
                        >
                          <p className="text-sm font-semibold">
                            {offer.totalPrice} {offer.currency}
                          </p>
                          <p className="text-xs text-gray-600">ID: {offer.id}</p>
                          {selectedHotelOfferId === offer.id && (
                            <p className="text-xs text-blue-600">✓ Sélectionné</p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <button
                  onClick={handleSearchHotels}
                  disabled={loading || !trip}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                >
                  {loading ? 'Recherche...' : 'Rechercher des hôtels'}
                </button>
              )}
            </div>

            <div>
              <h4 className="font-semibold mb-2">5.2 Create Booking Intent</h4>
              <button
                onClick={() => handleCreateBookingIntent('hotel')}
                disabled={loading || !selectedHotelOfferId}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {loading ? 'Création...' : 'Créer Booking Intent (Hotel)'}
              </button>
            </div>

            {bookingIntent && bookingIntent.type === 'hotel' && (
              <>
                <div>
                  <h4 className="font-semibold mb-2">5.3 Authorize Payment</h4>
                  <p className="text-sm text-gray-600 mb-2">
                    Status: <strong>{bookingIntent.status}</strong>
                  </p>
                  {paymentAuth ? (
                    <div className="p-4 bg-yellow-50 rounded-lg space-y-3">
                      <div>
                        <p className="text-sm font-semibold">
                          Payment Intent ID: {paymentAuth.stripePaymentIntentId}
                        </p>
                        <p className="text-xs text-gray-600 mt-1">Status: {paymentAuth.status}</p>
                      </div>
                      {polling && (
                        <div className="p-2 bg-blue-50 rounded border border-blue-200">
                          <div className="flex items-center">
                            <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-blue-600 mr-2"></div>
                            <p className="text-xs text-blue-700">
                              Attente de l&apos;autorisation du paiement...
                            </p>
                          </div>
                        </div>
                      )}
                      {pollingError && (
                        <div className="p-2 bg-red-50 rounded border border-red-200">
                          <p className="text-xs text-red-700">{pollingError}</p>
                        </div>
                      )}
                      {bookingIntent?.status === 'AUTHORIZED' ? (
                        <div className="p-2 bg-green-50 rounded border border-green-200">
                          <p className="text-xs text-green-700 font-semibold">
                            ✓ Paiement autorisé! Vous pouvez maintenant réserver l&apos;hôtel.
                          </p>
                        </div>
                      ) : (
                        <button
                          onClick={handleConfirmPayment}
                          disabled={loading || polling || bookingIntent?.status === 'AUTHORIZED'}
                          className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 text-sm"
                        >
                          {loading || polling
                            ? 'Confirmation...'
                            : 'Confirmer le paiement (Test Card)'}
                        </button>
                      )}
                    </div>
                  ) : (
                    <button
                      onClick={handleAuthorizePayment}
                      disabled={loading || bookingIntent.status !== 'INIT'}
                      className="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 disabled:opacity-50"
                    >
                      {loading ? 'Autorisation...' : 'Autoriser le paiement'}
                    </button>
                  )}
                </div>

                <div>
                  <h4 className="font-semibold mb-2">5.4 Book Hotel</h4>
                  <button
                    onClick={handleBookHotel}
                    disabled={loading || bookingIntent.status !== 'AUTHORIZED'}
                    className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                  >
                    {loading ? 'Réservation...' : "Réserver l'hôtel"}
                  </button>
                </div>

                <div>
                  <h4 className="font-semibold mb-2">5.5 Capture Payment</h4>
                  <button
                    onClick={handleCapturePayment}
                    disabled={loading || bookingIntent.status !== 'BOOKED'}
                    className="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 disabled:opacity-50"
                  >
                    {loading ? 'Capture...' : 'Capturer le paiement'}
                  </button>
                </div>
              </>
            )}
          </div>
        </Section>

        {loading && (
          <div className="fixed bottom-4 right-4 bg-blue-600 text-white px-4 py-2 rounded-lg shadow-lg">
            <div className="flex items-center">
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              Chargement...
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
