import CircuitBreaker from 'opossum';

export const makeBreaker = <T extends (...a: any[]) => any>(fn: T) =>
  new CircuitBreaker(fn, {
    timeout: 10000, // temps max par appel (augmenté pour les APIs externes)
    errorThresholdPercentage: 60, // ouvre le circuit si 60% d'échecs (plus tolérant)
    resetTimeout: 30000, // délai avant demi-ouverture (30s)
    rollingCountTimeout: 60000, // fenêtre de temps pour calculer les erreurs (60s)
    rollingCountBuckets: 10, // nombre de buckets pour la fenêtre glissante
    volumeThreshold: 5, // minimum d'appels avant d'évaluer le pourcentage d'erreur
  });
