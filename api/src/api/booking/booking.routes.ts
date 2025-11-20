import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import { createHotelBookingSchema } from './booking.validators';
import { createHotelBooking } from './booking.controller';

const r = Router();

/**
 * @swagger
 * /api/booking/hotel:
 *   post:
 *     summary: Create a hotel booking
 *     tags: [Booking]
 *     description: Create a confirmed hotel booking with guest information and payment details. This endpoint requires a valid hotel offer ID obtained from the hotel offers search.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - guests
 *               - roomAssociations
 *               - payment
 *             properties:
 *               guests:
 *                 type: array
 *                 description: List of guests staying at the hotel (1-9 guests maximum)
 *                 minItems: 1
 *                 maxItems: 9
 *                 items:
 *                   type: object
 *                   required:
 *                     - title
 *                     - firstName
 *                     - lastName
 *                     - phone
 *                     - email
 *                   properties:
 *                     tid:
 *                       type: integer
 *                       description: Optional traveler ID for internal reference
 *                       example: 1
 *                     title:
 *                       type: string
 *                       enum: [MR, MRS, MS, MISS, DR]
 *                       description: Guest title/salutation
 *                       example: MR
 *                     firstName:
 *                       type: string
 *                       description: Guest's first/given name (as it appears on ID)
 *                       minLength: 1
 *                       example: John
 *                     lastName:
 *                       type: string
 *                       description: Guest's last/family name (as it appears on ID)
 *                       minLength: 1
 *                       example: Doe
 *                     phone:
 *                       type: string
 *                       description: Contact phone number with country code (e.g., +33612345678)
 *                       minLength: 1
 *                       example: "+33612345678"
 *                     email:
 *                       type: string
 *                       format: email
 *                       description: Guest's email address for booking confirmation
 *                       example: "[email protected]"
 *               travelAgentEmail:
 *                 type: string
 *                 format: email
 *                 description: Optional email address of the travel agent managing this booking
 *                 example: "[email protected]"
 *               roomAssociations:
 *                 type: array
 *                 description: Association between guests and rooms (1-9 rooms maximum)
 *                 minItems: 1
 *                 maxItems: 9
 *                 items:
 *                   type: object
 *                   required:
 *                     - guestReferences
 *                     - hotelOfferId
 *                   properties:
 *                     guestReferences:
 *                       type: array
 *                       description: Array of guest TID references (as strings) who will stay in this room
 *                       minItems: 1
 *                       maxItems: 9
 *                       items:
 *                         type: string
 *                       example: ["1"]
 *                     hotelOfferId:
 *                       type: string
 *                       description: Unique hotel offer ID obtained from GET /api/hotel/offers
 *                       minLength: 1
 *                       example: "4L8PRJPEN7"
 *               payment:
 *                 type: object
 *                 description: Payment information (credit card only, as required by most hotels)
 *                 required:
 *                   - method
 *                   - vendorCode
 *                   - cardNumber
 *                   - expiryDate
 *                   - holderName
 *                 properties:
 *                   method:
 *                     type: string
 *                     enum: [CREDIT_CARD]
 *                     description: Payment method (only credit card is currently supported)
 *                     example: CREDIT_CARD
 *                   vendorCode:
 *                     type: string
 *                     enum: [VI, CA, AX, DC, JC, DS]
 *                     description: Card vendor code (VI=Visa, CA=Mastercard, AX=Amex, DC=Diners Club, JC=JCB, DS=Discover)
 *                     example: VI
 *                   cardNumber:
 *                     type: string
 *                     description: Credit card number (13-19 digits, no spaces or dashes)
 *                     minLength: 13
 *                     maxLength: 19
 *                     pattern: '^\d{13,19}$'
 *                     example: "4111111111111111"
 *                   expiryDate:
 *                     type: string
 *                     description: Card expiry date in YYYY-MM format (must be in the future)
 *                     pattern: '^\d{4}-\d{2}$'
 *                     example: "2026-12"
 *                   holderName:
 *                     type: string
 *                     description: Cardholder name (as it appears on the card, typically uppercase)
 *                     minLength: 1
 *                     example: "JOHN DOE"
 *           example:
 *             guests:
 *               - tid: 1
 *                 title: MR
 *                 firstName: John
 *                 lastName: Doe
 *                 phone: "+33612345678"
 *                 email: "[email protected]"
 *             travelAgentEmail: "[email protected]"
 *             roomAssociations:
 *               - guestReferences: ["1"]
 *                 hotelOfferId: "4L8PRJPEN7"
 *             payment:
 *               method: CREDIT_CARD
 *               vendorCode: VI
 *               cardNumber: "4111111111111111"
 *               expiryDate: "2026-12"
 *               holderName: "JOHN DOE"
 *     responses:
 *       201:
 *         description: Booking created successfully - Returns confirmation details including booking ID and provider confirmation number
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         description: Unique booking identifier
 *                       providerConfirmationId:
 *                         type: string
 *                         description: Hotel's confirmation number
 *                       hotel:
 *                         type: object
 *                         description: Booked hotel details
 *                       checkInDate:
 *                         type: string
 *                         format: date
 *                       checkOutDate:
 *                         type: string
 *                         format: date
 *                       price:
 *                         type: object
 *                         properties:
 *                           currency:
 *                             type: string
 *                           total:
 *                             type: string
 *       400:
 *         description: Bad request - Invalid parameters or validation errors
 *       422:
 *         description: Validation error - Detailed error information about invalid fields
 *       500:
 *         description: Internal server error
 */
r.post('/hotel', validate(createHotelBookingSchema), createHotelBooking);

export default r;
