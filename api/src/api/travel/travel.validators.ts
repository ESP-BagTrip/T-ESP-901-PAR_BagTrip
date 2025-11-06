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
