import { z } from 'zod';

const expiryDateRegex = /^\d{4}-\d{2}$/;

const guestSchema = z.object({
  tid: z.number().int().optional(),
  title: z.enum(['MR', 'MRS', 'MS', 'MISS', 'DR'], {
    message: 'title must be one of: MR, MRS, MS, MISS, DR',
  }),
  firstName: z.string().min(1, 'firstName is required'),
  lastName: z.string().min(1, 'lastName is required'),
  phone: z.string().min(1, 'phone is required'),
  email: z.string().email('email must be a valid email address'),
});

const paymentSchema = z.object({
  method: z.enum(['CREDIT_CARD'], {
    message: 'method must be CREDIT_CARD',
  }),
  vendorCode: z.enum(['VI', 'CA', 'AX', 'DC', 'JC', 'DS'], {
    message: 'vendorCode must be one of: VI (Visa), CA (Mastercard), AX (Amex), DC, JC, DS',
  }),
  cardNumber: z.string().min(13).max(19, 'cardNumber must be between 13 and 19 digits'),
  expiryDate: z
    .string()
    .regex(expiryDateRegex, 'expiryDate must be in YYYY-MM format')
    .refine(
      (date) => {
        const [year, month] = date.split('-').map(Number);
        if (month < 1 || month > 12) return false;
        const expiry = new Date(year, month - 1);
        const now = new Date();
        return expiry > now;
      },
      { message: 'expiryDate must be in the future' }
    ),
  holderName: z.string().min(1, 'holderName is required'),
});

const roomAssociationSchema = z.object({
  guestReferences: z
    .array(z.string())
    .min(1, 'At least one guest reference is required')
    .max(9, 'Maximum 9 guest references per room'),
  hotelOfferId: z.string().min(1, 'hotelOfferId is required'),
});

export const createHotelBookingSchema = z.object({
  body: z.object({
    guests: z
      .array(guestSchema)
      .min(1, 'At least one guest is required')
      .max(9, 'Maximum 9 guests per booking'),
    travelAgentEmail: z.string().email('travelAgentEmail must be a valid email').optional(),
    roomAssociations: z
      .array(roomAssociationSchema)
      .min(1, 'At least one room association is required')
      .max(9, 'Maximum 9 room associations per booking'),
    payment: paymentSchema,
  }),
});
