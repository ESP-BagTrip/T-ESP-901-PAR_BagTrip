import { z } from 'zod';

export const nearbySearchQuerySchema = z.object({
  query: z.object({
    latitude: z.coerce
      .number()
      .min(-90, 'latitude must be >= -90')
      .max(90, 'latitude must be <= 90'),
    longitude: z.coerce
      .number()
      .min(-180, 'longitude must be >= -180')
      .max(180, 'longitude must be <= 180'),
    radius: z.coerce
      .number()
      .positive('radius must be positive')
      .max(50000, 'radius must be <= 50000 meters')
      .optional(),
    types: z
      .string()
      .optional()
      .transform((val) => (val ? val.split(',').map((t) => t.trim()) : undefined)),
    maxResults: z.coerce
      .number()
      .int()
      .min(1, 'maxResults must be >= 1')
      .max(20, 'maxResults must be <= 20')
      .optional(),
    rankBy: z.enum(['POPULARITY', 'DISTANCE'], {
      message: 'rankBy must be POPULARITY or DISTANCE',
    }).optional(),
    language: z.string().length(2, 'language must be a 2-letter ISO 639-1 code').optional(),
    source: z.enum(['hotel', 'manual', 'current']).optional(),
  }),
});

export const textSearchQuerySchema = z.object({
  query: z.object({
    q: z.string().min(1, 'query (q) is required'),
    latitude: z.coerce
      .number()
      .min(-90)
      .max(90)
      .optional(),
    longitude: z.coerce
      .number()
      .min(-180)
      .max(180)
      .optional(),
    radius: z.coerce
      .number()
      .positive()
      .max(50000)
      .optional(),
    type: z.string().optional(),
    maxResults: z.coerce
      .number()
      .int()
      .min(1)
      .max(20)
      .optional(),
    language: z.string().length(2).optional(),
    minRating: z.coerce
      .number()
      .min(0, 'minRating must be >= 0')
      .max(5, 'minRating must be <= 5')
      .optional(),
    openNow: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
  }),
});

export const placeDetailsParamSchema = z.object({
  params: z.object({
    placeId: z.string().min(1, 'placeId is required'),
  }),
  query: z.object({
    language: z.string().length(2).optional(),
  }).optional(),
});
