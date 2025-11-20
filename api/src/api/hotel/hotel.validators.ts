import { z } from 'zod';

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const hotelListSearchQuerySchema = z.object({
  query: z.object({
    cityCode: z
      .string()
      .length(3, 'cityCode must be a 3-letter IATA code')
      .regex(/^[A-Z]{3}$/, 'cityCode must be uppercase letters'),
    radius: z.coerce.number().positive('radius must be a positive number').optional(),
    radiusUnit: z.enum(['KM', 'MILE'], { message: 'radiusUnit must be KM or MILE' }).optional(),
    chainCodes: z.string().optional(),
    amenities: z.string().optional(),
    ratings: z.string().optional(),
    hotelSource: z
      .enum(['ALL', 'BEDBANK', 'DIRECTCHAIN'], {
        message: 'hotelSource must be one of: ALL, BEDBANK, DIRECTCHAIN',
      })
      .optional(),
  }),
});

export const hotelSearchQuerySchema = z.object({
  query: z.object({
    hotelIds: z.string().min(1, 'hotelIds is required (comma-separated Amadeus hotel IDs)'),
    adults: z.coerce.number().int().min(1).max(9, 'adults must be between 1 and 9'),
    checkInDate: z
      .string()
      .regex(dateRegex, 'checkInDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'checkInDate must be a valid date' }
      )
      .optional(),
    checkOutDate: z
      .string()
      .regex(dateRegex, 'checkOutDate must be in YYYY-MM-DD format')
      .refine(
        (date) => {
          const d = new Date(date);
          return !isNaN(d.getTime());
        },
        { message: 'checkOutDate must be a valid date' }
      )
      .optional(),
    roomQuantity: z.coerce
      .number()
      .int()
      .min(1)
      .max(9, 'roomQuantity must be between 1 and 9')
      .optional(),
    priceRange: z.string().optional(),
    currency: z.string().length(3, 'currency must be a 3-letter ISO 4217 code').optional(),
    paymentPolicy: z
      .enum(['NONE', 'GUARANTEE', 'DEPOSIT'], {
        message: 'paymentPolicy must be one of: NONE, GUARANTEE, DEPOSIT',
      })
      .optional(),
    boardType: z
      .enum(['ROOM_ONLY', 'BREAKFAST', 'HALF_BOARD', 'FULL_BOARD', 'ALL_INCLUSIVE'], {
        message:
          'boardType must be one of: ROOM_ONLY, BREAKFAST, HALF_BOARD, FULL_BOARD, ALL_INCLUSIVE',
      })
      .optional(),
    includeClosed: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    bestRateOnly: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
  }),
});

export const hotelOfferDetailsParamSchema = z.object({
  params: z.object({
    offerId: z.string().min(1, 'offerId is required'),
  }),
});
