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
 *                       example: 1
 *                     title:
 *                       type: string
 *                       enum: [MR, MRS, MS, MISS, DR]
 *                       example: MR
 *                     firstName:
 *                       type: string
 *                       example: John
 *                     lastName:
 *                       type: string
 *                       example: Doe
 *                     phone:
 *                       type: string
 *                       example: "+33612345678"
 *                     email:
 *                       type: string
 *                       example: "[email protected]"
 *               travelAgentEmail:
 *                 type: string
 *                 example: "[email protected]"
 *               roomAssociations:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - guestReferences
 *                     - hotelOfferId
 *                   properties:
 *                     guestReferences:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: ["1"]
 *                     hotelOfferId:
 *                       type: string
 *                       example: "4L8PRJPEN7"
 *               payment:
 *                 type: object
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
 *                     example: CREDIT_CARD
 *                   vendorCode:
 *                     type: string
 *                     enum: [VI, CA, AX, DC, JC, DS]
 *                     example: VI
 *                   cardNumber:
 *                     type: string
 *                     example: "4111111111111111"
 *                   expiryDate:
 *                     type: string
 *                     example: "2026-12"
 *                   holderName:
 *                     type: string
 *                     example: "JOHN DOE"
 *     responses:
 *       201:
 *         description: Booking created successfully
 *       400:
 *         description: Bad request
 *       500:
 *         description: Internal server error
 */
r.post('/hotel', validate(createHotelBookingSchema), createHotelBooking);

export default r;
