import Anthropic from '@anthropic-ai/sdk';
import 'dotenv/config';

// Initialize Anthropic client with API key from environment
// Supports both ANTHROPIC_API_KEY (SDK default) and CLAUDE_API_KEY (custom)
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY,
});

// Model configuration based on premium status
const MODEL_CONFIG = {
  premium: 'claude-sonnet-4-5',
  free: 'claude-haiku-4-5-20251001'
};

// Category-specific instructions
const categoryInstructions = {
  'General': 'Create a clear, specific, and well-structured prompt for any AI assistant.',
  'Image Generation': 'Create a detailed image generation prompt optimized for tools like Midjourney, DALL-E, or Stable Diffusion. Include style, lighting, composition, mood, and technical details.',
  'Coding': 'Create a precise coding prompt that includes the programming language, desired functionality, expected inputs/outputs, and any constraints or preferences.',
  'Writing': 'Create a comprehensive writing prompt that specifies tone, audience, format, length, style, and key points to cover.',
  'Business': 'Create a professional business prompt that is formal, specific, includes context, desired outcomes, and any relevant constraints.'
};

// Tone instructions
const toneInstructions = {
  'Auto': '',
  'Professional': 'Use a formal, professional tone throughout the prompt.',
  'Creative': 'Use an imaginative, creative tone that encourages unique and artistic outputs.',
  'Casual': 'Use a friendly, conversational tone that feels approachable and relaxed.',
  'Persuasive': 'Use a compelling, persuasive tone designed to convince or influence.',
  'Technical': 'Use precise technical language appropriate for expert-level understanding.'
};

/**
 * Generate system prompt based on category, tone, and persona
 * @param {string} category - The prompt category
 * @param {string} tone - The tone style
 * @param {string} persona - User's persona/context
 * @returns {string} - System prompt for Claude
 */
function getSystemPrompt(category, tone = 'Auto', persona = null) {
  let personaContext = '';
  if (persona && persona.trim()) {
    personaContext = `\n\nUser context: ${persona.trim()}. Keep this in mind when enhancing prompts - tailor the output to be relevant to this user's profession or role.`;
  }

  let toneInstruction = '';
  if (tone && tone !== 'Auto' && toneInstructions[tone]) {
    toneInstruction = `\n\nTone requirement: ${toneInstructions[tone]}`;
  }

  return `You are a world-class prompt engineering expert with deep knowledge of how to communicate effectively with AI models including ChatGPT, Claude, Gemini, Midjourney, and others.
${personaContext}
Your ONLY job is to transform rough, casual, or voice-recorded user input into a professional, structured, detailed, and highly effective prompt that will produce exceptional results from any AI model.

STRICT RULES:
1. ONLY return the enhanced prompt — nothing else. No explanations, no preamble, no "Here is your enhanced prompt:", just the prompt itself.
2. Keep the user's original intent 100% intact — never change what they want, only how they ask for it.
3. Add specificity, context, structure, and clarity that the user implied but didn't explicitly state.
4. Remove all filler words, hesitations, and informal language.
5. Make the prompt actionable and specific.
6. For the category "${category || 'General'}": ${categoryInstructions[category] || categoryInstructions['General']}${toneInstruction}

Transform the following rough input into a professional prompt:`;
}

/**
 * Enhance a prompt using Claude API
 * @param {string} roughPrompt - The rough/user prompt to enhance
 * @param {string} category - The category for context
 * @param {boolean} isPremium - Whether to use premium model (default: false)
 * @param {string} tone - The tone style (default: 'Auto')
 * @param {string} persona - User's persona/context (default: null)
 * @returns {Promise<string>} - Enhanced prompt
 */
async function enhancePrompt(roughPrompt, category = 'General', isPremium = false, tone = 'Auto', persona = null) {
  const model = isPremium ? MODEL_CONFIG.premium : MODEL_CONFIG.free;

  console.log(`Using model: ${model} (isPremium: ${isPremium}, tone: ${tone})`);

  const message = await anthropic.messages.create({
    model: model,
    max_tokens: 1024,
    system: getSystemPrompt(category, tone, persona),
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

/**
 * Generate 3 variations of a prompt (Formal, Creative, Concise)
 * @param {string} roughPrompt - The rough/user prompt
 * @param {string} category - The category for context
 * @param {boolean} isPremium - Whether to use premium model
 * @returns {Promise<string[]>} - Array of 3 variations
 */
async function generateVariations(roughPrompt, category = 'General', isPremium = false) {
  const model = isPremium ? MODEL_CONFIG.premium : MODEL_CONFIG.free;

  console.log(`Generating variations with model: ${model}`);

  const systemPrompt = `You are a prompt engineering expert. Given a rough prompt, generate exactly 3 different professional versions:

1. FORMAL: Professional, structured, detailed - suitable for business or academic contexts
2. CREATIVE: Imaginative, expressive, unique angle - encourages artistic or innovative outputs
3. CONCISE: Short, sharp, maximum impact with minimum words - gets straight to the point

For the category "${category}": ${categoryInstructions[category] || categoryInstructions['General']}

IMPORTANT: Return ONLY a valid JSON array with exactly 3 strings. No explanations, no labels, just the prompts in order [formal, creative, concise].
Example output: ["First variation...", "Second variation...", "Third variation..."]`;

  const message = await anthropic.messages.create({
    model: model,
    max_tokens: 2048,
    system: systemPrompt,
    messages: [
      {
        role: 'user',
        content: roughPrompt.trim()
      }
    ]
  });

  // Extract text from Claude's response
  const textBlock = message.content.find(block => block.type === 'text');
  if (!textBlock) {
    throw new Error('No text content in Claude response');
  }

  // Parse JSON array from response
  try {
    // Try to extract JSON array from the response
    let responseText = textBlock.text.trim();

    // Remove any markdown code blocks if present
    if (responseText.startsWith('```')) {
      responseText = responseText.replace(/```json?\n?/g, '').replace(/```/g, '').trim();
    }

    const variations = JSON.parse(responseText);

    if (!Array.isArray(variations) || variations.length !== 3) {
      throw new Error('Invalid response format');
    }

    return variations;
  } catch (e) {
    console.error('Failed to parse variations:', e);
    throw new Error('Failed to generate valid variations');
  }
}

export { enhancePrompt, generateVariations };
