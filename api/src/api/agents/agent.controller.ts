import { Request, Response, NextFunction } from 'express';
import { chatWithAgent } from '../../domain/agents/agent.service';
import { AgentChatRequest, ThreadMessage } from '../../domain/agents/agent.types';

interface AuthRequest extends Request {
  userId?: string;
}

/**
 * Chat with the agent
 * Accepts a conversation thread and returns the updated thread
 */
export async function chatAgent(req: Request, res: Response, next: NextFunction) {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.userId;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const { prompt, conversation } = req.body as {
      prompt: string;
      conversation?: ThreadMessage[];
    };

    // Create request object with thread
    const agentRequest: AgentChatRequest = {
      prompt,
      conversation,
    };

    // Call the agent service
    const result = await chatWithAgent(userId, agentRequest);

    res.json(result);
  } catch (e) {
    next(e);
  }
}

