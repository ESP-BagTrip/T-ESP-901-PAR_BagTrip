import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import { authenticate } from '../../app/middleware/auth.middleware';
import { agentChatRequestSchema } from './agent.validators';
import { chatAgent } from './agent.controller';

const r = Router();

/**
 * @swagger
 * /api/agents/chat:
 *   post:
 *     summary: Chat with the AI agent
 *     tags: [Agents]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - prompt
 *             properties:
 *               prompt:
 *                 type: string
 *                 description: The user's message/prompt
 *                 example: "Find me airports in Paris"
 *               conversation:
 *                 type: array
 *                 description: Optional conversation history
 *                 items:
 *                   type: object
 *                   properties:
 *                     role:
 *                       type: string
 *                       enum: [user, assistant, human, ai]
 *                     content:
 *                       type: string
 *     responses:
 *       200:
 *         description: Agent response
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 response:
 *                   type: string
 *                 userId:
 *                   type: string
 *       400:
 *         description: Bad request - Invalid parameters
 *       401:
 *         description: Unauthorized - Missing or invalid token
 *       500:
 *         description: Internal server error
 */
r.post('/chat', authenticate, validate(agentChatRequestSchema), chatAgent);

export default r;

