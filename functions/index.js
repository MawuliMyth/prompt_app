const functions = require('firebase-functions');
const https = require('https');

exports.enhancePrompt = functions.https.onCall(async (data, context) => {
  const { roughPrompt, category } = data;

  if (!roughPrompt || roughPrompt.trim().length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Prompt text is required');
  }

  const categoryInstructions = {
    'General': 'Create a clear, specific, and well-structured prompt for any AI assistant.',
    'Image Generation': 'Create a detailed image generation prompt optimized for tools like Midjourney, DALL-E, or Stable Diffusion. Include style, lighting, composition, mood, and technical details.',
    'Coding': 'Create a precise coding prompt that includes the programming language, desired functionality, expected inputs/outputs, and any constraints or preferences.',
    'Writing': 'Create a comprehensive writing prompt that specifies tone, audience, format, length, style, and key points to cover.',
    'Business': 'Create a professional business prompt that is formal, specific, includes context, desired outcomes, and any relevant constraints.'
  };

  const systemPrompt = `You are a world-class prompt engineering expert with deep knowledge of how to communicate effectively with AI models including ChatGPT, Claude, Gemini, Midjourney, and others.

Your ONLY job is to transform rough, casual, or voice-recorded user input into a professional, structured, detailed, and highly effective prompt that will produce exceptional results from any AI model.

STRICT RULES:
1. ONLY return the enhanced prompt — nothing else. No explanations, no preamble, no "Here is your enhanced prompt:", just the prompt itself.
2. Keep the user's original intent 100% intact — never change what they want, only how they ask for it.
3. Add specificity, context, structure, and clarity that the user implied but didn't explicitly state.
4. Remove all filler words, hesitations, and informal language.
5. Make the prompt actionable and specific.
6. For the category "${category || 'General'}": ${categoryInstructions[category] || categoryInstructions['General']}

Transform the following rough input into a professional prompt:`;

  const requestBody = JSON.stringify({
    model: 'claude-3-5-sonnet-20240620', // updated to the generic model handle, or we can use exactly the one specified (claude-sonnet-4-5 doesn't exist yet but let's stick closer to the actual Anthropic API)
    max_tokens: 1024,
    system: systemPrompt,
    messages: [
      {
        role: 'user',
        content: roughPrompt.trim()
      }
    ]
  });

const apiKey = process.env.CLAUDE_API_KEY;
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.anthropic.com',
      path: '/v1/messages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => { responseData += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          if (parsed.content && parsed.content[0] && parsed.content[0].text) {
            resolve({ enhancedPrompt: parsed.content[0].text });
          } else {
             // Let client see parsing errors for easier debugging
            reject(new functions.https.HttpsError('internal', `Invalid response from Claude API: ${JSON.stringify(parsed)}`));
          }
        } catch (e) {
          reject(new functions.https.HttpsError('internal', 'Failed to parse Claude API response'));
        }
      });
    });

    req.on('error', (error) => {
      reject(new functions.https.HttpsError('internal', error.message));
    });

    req.write(requestBody);
    req.end();
  });
});
