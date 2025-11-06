import { z } from 'zod';

export const locationKeywordSearchQuerySchema = z.object({
  query: z.object({
    subType: z.string().min(1, 'subType is required (e.g., "CITY,AIRPORT")'),
    keyword: z.string().min(1, 'keyword is required'),
  }),
});

export const locationIdSearchQuerySchema = z.object({
  params: z.object({
    id: z.string().min(1, 'id is required'),
  }),
});

export const locationNearestSearchQuerySchema = z.object({
  query: z.object({
    latitude: z.coerce.number().min(-90).max(90, 'latitude must be between -90 and 90'),
    longitude: z.coerce.number().min(-180).max(180, 'longitude must be between -180 and 180'),
  }),
});
