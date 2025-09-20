import { z } from 'zod';

export const locationSearchQuerySchema = z.object({
  query: z.object({
    subType: z.string().min(1, 'subType is required (e.g., "CITY,AIRPORT")'),
    keyword: z.string().min(1, 'keyword is required'),
  }),
});
