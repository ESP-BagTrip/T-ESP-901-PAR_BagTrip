import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  REQUEST_TIMEOUT_MS: z.coerce.number().default(3000),

  DATABASE_URL: z.string().url().default('postgresql://postgres:postgres@localhost:5432/postgres'),

  AMADEUS_CLIENT_ID: z.string().min(1, 'Missing AMADEUS_CLIENT_ID'),
  AMADEUS_CLIENT_SECRET: z.string().min(1, 'Missing AMADEUS_CLIENT_SECRET'),
  // Sandbox par défaut (changeable via env)
  AMADEUS_BASE_URL: z.string().url().default('https://test.api.amadeus.com'),

  GOOGLE_GENAI_API_KEY: z.string().min(1, 'Missing GOOGLE_GENAI_API_KEY'),
});

export const env = schema.parse(process.env);
