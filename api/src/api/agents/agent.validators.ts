import { z } from 'zod';

/**
 * Schema for a message in the conversation thread
 */
const threadMessageSchema = z.object({
  role: z.enum(['user', 'assistant', 'system', 'tool']),
  content: z.string(),
  toolCallId: z.string().optional(),
  toolName: z.string().optional(),
  toolArgs: z.record(z.string(), z.any()).optional(),
});

/**
 * Schema for agent chat request validation
 */
export const agentChatRequestSchema = z.object({
  body: z.object({
    prompt: z.string().min(1, 'prompt is required'),
    conversation: z.array(threadMessageSchema).optional(),
  }),
});
