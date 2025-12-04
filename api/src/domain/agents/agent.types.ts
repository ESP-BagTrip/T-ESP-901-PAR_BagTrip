/**
 * Message in the conversation thread
 */
export interface ThreadMessage {
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  toolCallId?: string;
  toolName?: string;
  toolArgs?: Record<string, any>;
}

/**
 * Request to chat with an agent
 * conversation: thread complet de la conversation (incluant tool calls et résultats)
 */
export interface AgentChatRequest {
  prompt: string;
  conversation?: ThreadMessage[];
}

/**
 * Response from the agent
 * thread: thread complet mis à jour avec la nouvelle interaction
 */
export interface AgentChatResponse {
  response: string;
  userId: string;
  thread: ThreadMessage[];
}

