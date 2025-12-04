import { ChatGoogleGenerativeAI } from '@langchain/google-genai';
import { HumanMessage, AIMessage, ToolMessage } from '@langchain/core/messages';
import { createAgent } from 'langchain';
import { env } from '../../config/env';
import { getTravelTools } from './adapters/travel.adapter';
import { AgentChatRequest, AgentChatResponse, ThreadMessage } from './agent.types';

/**
 * Create a system prompt that includes user context
 */
function createSystemPrompt(userId: string): string {
  return `You are a helpful travel assistant. You help users find locations, cities, airports, and travel information.

User ID: ${userId}

You have access to tools that allow you to search for locations. When a user asks about finding a place, city, or airport, use the search_locations_by_keyword tool.

Be friendly, helpful, and provide clear information. If you need to search for locations, use the available tools. Always respond in a conversational manner.`;
}

/**
 * Chat with an agent
 */
export async function chatWithAgent(
  userId: string,
  request: AgentChatRequest
): Promise<AgentChatResponse> {
  // Initialize the LLM
  const model = new ChatGoogleGenerativeAI({
    model: 'gemini-2.5-flash-lite',
    temperature: 0.7,
    apiKey: env.GOOGLE_GENAI_API_KEY,
  });

  // Get available tools
  const tools = getTravelTools();

  // Create system prompt with user context
  const systemPrompt = createSystemPrompt(userId);

  // Create the agent
  const agent = await createAgent({
    model,
    tools,
  });

  // Build the complete thread starting with the conversation history
  const thread: ThreadMessage[] = request.conversation ? [...request.conversation] : [];

  // Add the current user message to the thread
  thread.push({
    role: 'user',
    content: request.prompt,
  });

  // Convert thread to LangChain format for the agent
  // We need to convert ThreadMessage[] to the format expected by agent.invoke
  const historyMessages: Array<{
    role: 'user' | 'assistant' | 'tool';
    content: string;
    tool_call_id?: string;
  }> = [];

  if (request.conversation) {
    for (const msg of request.conversation) {
      if (msg.role === 'system') {
        // System messages are handled separately
        continue;
      } else if (msg.role === 'user') {
        historyMessages.push({ role: 'user', content: msg.content });
      } else if (msg.role === 'assistant') {
        historyMessages.push({ role: 'assistant', content: msg.content });
      } else if (msg.role === 'tool' && msg.toolCallId) {
        historyMessages.push({
          role: 'tool',
          content: msg.content,
          tool_call_id: msg.toolCallId,
        });
      }
    }
  }

  // Add system message with user context
  const systemMessage = { role: 'system' as const, content: systemPrompt };

  // Add the current user message
  const userMessage = { role: 'user' as const, content: request.prompt };

  // Prepare messages for the agent
  const messages = [systemMessage, ...historyMessages, userMessage];

  // Execute the agent
  const result = await agent.invoke({
    messages,
  });

  // Process all messages in the result to add to the thread
  if (result.messages) {
    for (const msg of result.messages) {
      // Skip system messages in the thread (they're already in the context)
      if (msg.getType() === 'system') {
        continue;
      }

      // Skip user messages from result (we already have them in the thread)
      if (msg instanceof HumanMessage) {
        continue;
      }

      // Handle AIMessage
      if (msg instanceof AIMessage) {
        // Add the assistant message
        thread.push({
          role: 'assistant',
          content: msg.content?.toString() || '',
        });

        // Add tool calls if any
        if (msg.tool_calls && msg.tool_calls.length > 0) {
          for (const toolCall of msg.tool_calls) {
            thread.push({
              role: 'tool',
              content: '', // Will be filled by tool result
              toolCallId: toolCall.id,
              toolName: toolCall.name,
              toolArgs: toolCall.args as Record<string, any>,
            });
          }
        }
      } else if (msg instanceof ToolMessage) {
        // This is a tool result - update the corresponding tool call entry
        const toolCallId = msg.tool_call_id;
        const toolCallEntry = thread.find(
          (entry) => entry.role === 'tool' && entry.toolCallId === toolCallId
        );
        if (toolCallEntry) {
          toolCallEntry.content = msg.content?.toString() || '';
        } else {
          // If we can't find the tool call entry, add it as a new entry
          thread.push({
            role: 'tool',
            content: msg.content?.toString() || '',
            toolCallId: toolCallId,
          });
        }
      }
    }
  }

  // Extract the final response from the last assistant message
  const assistantMessages = thread.filter((msg) => msg.role === 'assistant');
  const response =
    assistantMessages[assistantMessages.length - 1]?.content ||
    'I apologize, but I could not generate a response.';

  return {
    response,
    userId,
    thread,
  };
}
