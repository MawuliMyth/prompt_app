import Anthropic from '@anthropic-ai/sdk';
import 'dotenv/config';

const anthropic = new Anthropic();

// Category-specific instructions (migrated from Firebase Functions)
const categoryInstructions = {
  'General': 'Create a clear, specific, and well-structured prompt for any AI assistant.',
  'Image Generation': 'Create a detailed image generation prompt optimized for tools like Midjourney, DALL-E, or Stable Diffusion. Include style, lighting, composition, mood, and technical details.',
  'Coding': 'Create a precise coding prompt that includes the programming language, desired functionality, expected inputs/outputs, and any constraints or preferences.',
  'Writing': 'Create a comprehensive writing prompt that specifies tone, audience, format, length, style, and key points to cover.',
  'Business': 'Create a professional business prompt that is formal, specific, includes context, desired outcomes, and any relevant constraints.'
};

/**
 * Generate system prompt based on category
 * @param {string} category - The prompt category
 * @returns {string} - System prompt for Claude
 */
function getSystemPrompt(category) {
  return `You are a world-class prompt engineering expert with deep knowledge of how to communicate effectively with AI models including ChatGPT, Claude, Gemini, Midjourney, and others.

Your ONLY job is to transform rough, casual, or voice-recorded user input into a professional, structured, detailed, and highly effective prompt that will produce exceptional results from any AI model.

STRICT RULES:
1. ONLY return the enhanced prompt — nothing else. No explanations, no preamble, no "Here is your enhanced prompt:", just the prompt itself.
2. Keep the user's original intent 100% intact — never change what they want, only how they ask for it.
3. Add specificity, context, structure, and clarity that the user implied but didn't explicitly state.
4. Remove all filler words, hesitations, and informal language.
5. Make the prompt actionable and specific.
6. For the category "${category || 'General'}": ${categoryInstructions[category] || categoryInstructions['General']}

Transform the following rough input into a professional prompt:`;
}

/**
 * Enhance a prompt using Claude API
 * @param {string} roughPrompt - The rough/user prompt to enhance
 * @param {string} category - The category for context
 * @returns {Promise<string>} - Enhanced prompt
 */
async function enhancePrompt(roughPrompt, category = 'General') {
  const message = await anthropic.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 1024,
    system: getSystemPrompt(category),
    messages: [
      {
        role: 'user',
        content: roughPrompt.trim()
      }
    ]
  });

  // Extract text from Claude's response
  const textBlock = message.content.find(block => block.type === 'text');
  if (textBlock) {
    return textBlock.text;
  }

  throw new Error('No text content in Claude response');
}

export { enhancePrompt };
