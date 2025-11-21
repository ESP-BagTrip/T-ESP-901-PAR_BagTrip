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

// ============================================================================
// FLIGHT VALIDATORS
// ============================================================================

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const flightOfferSearchQuerySchema = z.object({
  query: z.object({
    originLocationCode: z.string().min(1, 'originLocationCode is required (IATA code)'),
    destinationLocationCode: z.string().min(1, 'destinationLocationCode is required (IATA code)'),
    departureDate: z
      .string()
      .regex(dateRegex, 'departureDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'departureDate must be a valid date' }
      ),
    adults: z.coerce.number().int().min(1).max(9, 'adults must be between 1 and 9'),
    returnDate: z
      .string()
      .regex(dateRegex, 'returnDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'returnDate must be a valid date' }
      )
      .optional(),
    children: z.coerce.number().int().min(0).max(9, 'children must be between 0 and 9').optional(),
    infants: z.coerce.number().int().min(0).max(9, 'infants must be between 0 and 9').optional(),
    travelClass: z
      .enum(['ECONOMY', 'PREMIUM_ECONOMY', 'BUSINESS', 'FIRST'], {
        message: 'travelClass must be one of: ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST',
      })
      .optional(),
    nonStop: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    currencyCode: z.string().length(3, 'currencyCode must be a 3-letter ISO 4217 code').optional(),
    maxPrice: z.coerce.number().int().positive('maxPrice must be a positive integer').optional(),
    max: z.coerce.number().int().min(1).max(250, 'max must be between 1 and 250').optional(),
    includedAirlineCodes: z.string().optional(),
    excludedAirlineCodes: z.string().optional(),
  }),
});

export const flightDestinationSearchQuerySchema = z.object({
  query: z.object({
    origin: z.string().min(1, 'origin is required (IATA code)'),
    departureDate: z
      .string()
      .regex(dateRegex, 'departureDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'departureDate must be a valid date' }
      )
      .optional(),
    oneWay: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    duration: z.coerce.number().int().positive('duration must be a positive integer').optional(),
    nonStop: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    maxPrice: z.coerce.number().int().positive('maxPrice must be a positive integer').optional(),
    viewBy: z
      .enum(['DURATION', 'COUNTRY', 'DATE', 'DESTINATION', 'WEEK'], {
        message: 'viewBy must be one of: DURATION, COUNTRY, DATE, DESTINATION, WEEK',
      })
      .optional(),
  }),
});

export const flightCheapestDateSearchQuerySchema = z.object({
  query: z.object({
    origin: z.string().min(1, 'origin is required (IATA code)'),
    destination: z.string().min(1, 'destination is required (IATA code)'),
    departureDate: z
      .string()
      .regex(dateRegex, 'departureDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'departureDate must be a valid date' }
      )
      .optional(),
    oneWay: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    duration: z.coerce.number().int().positive('duration must be a positive integer').optional(),
    nonStop: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    maxPrice: z.coerce.number().int().positive('maxPrice must be a positive integer').optional(),
    viewBy: z
      .enum(['DATE', 'DURATION', 'WEEK'], {
        message: 'viewBy must be one of: DATE, DURATION, WEEK',
      })
      .optional(),
  }),
});
