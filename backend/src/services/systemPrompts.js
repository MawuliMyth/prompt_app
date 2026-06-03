function createError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

const SYSTEM_PROMPTS_COLLECTION = 'appConfig';
const SYSTEM_PROMPTS_DOCUMENT = 'systemPrompts';

const DEFAULT_SYSTEM_PROMPTS = Object.freeze({
  enhance: {
    role:
      'You are a world-class prompt engineering expert with deep knowledge of how to communicate effectively with AI models including ChatGPT, Claude, Gemini, Midjourney, and others.',
    task:
      'Your ONLY job is to transform rough, casual, or voice-recorded user input into a professional, structured, detailed, and highly effective prompt that will produce exceptional results from any AI model.',
    personaTemplate:
      'User context: {{persona}}. Keep this in mind when enhancing prompts - tailor the output to be relevant to this user\'s profession or role.',
    rules: [
      'ONLY return the enhanced prompt - nothing else. No explanations, no preamble, no "Here is your enhanced prompt:", just the prompt itself.',
      'Keep the user\'s original intent 100% intact - never change what they want, only how they ask for it.',
      'Add specificity, context, structure, and clarity that the user implied but didn\'t explicitly state.',
      'Remove all filler words, hesitations, and informal language.',
      'Make the prompt actionable and specific.',
    ],
    categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
    toneLineTemplate: 'Tone requirement: {{toneInstruction}}',
    closingInstruction:
      'Transform the following rough input into a professional prompt:',
  },
  variations: {
    intro:
      'You are a prompt engineering expert. Given a rough prompt, generate exactly 3 different professional versions:',
    styles: [
      'FORMAL: Professional, structured, detailed - suitable for business or academic contexts',
      'CREATIVE: Imaginative, expressive, unique angle - encourages artistic or innovative outputs',
      'CONCISE: Short, sharp, maximum impact with minimum words - gets straight to the point',
    ],
    categoryLineTemplate: 'For the category "{{category}}": {{instruction}}',
    outputInstruction:
      'IMPORTANT: Return ONLY a valid JSON array with exactly 3 strings. No explanations, no labels, just the prompts in order [formal, creative, concise].',
    exampleOutput:
      'Example output: ["First variation...", "Second variation...", "Third variation..."]',
  },
});

function mergeObjects(base, override) {
  if (!override || typeof override !== 'object' || Array.isArray(override)) {
    return base;
  }

  const merged = { ...base };

  for (const [key, value] of Object.entries(override)) {
    if (Array.isArray(value)) {
      merged[key] = [...value];
    } else if (value && typeof value === 'object') {
      merged[key] = mergeObjects(base[key] ?? {}, value);
    } else if (typeof value !== 'undefined') {
      merged[key] = value;
    }
  }

  return merged;
}

function sanitizeString(value, fieldName) {
  if (typeof value !== 'string') {
    throw createError(400, `${fieldName} must be a string.`, 'invalid-system-prompts');
  }

  return value.trim();
}

function sanitizeStringArray(value, fieldName) {
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
    throw createError(400, `${fieldName} must be an array of strings.`, 'invalid-system-prompts');
  }

  return value.map((item) => item.trim());
}

function validateSystemPrompts(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw createError(400, 'System prompts payload must be an object.', 'invalid-system-prompts');
  }

  const enhance = input.enhance ?? {};
  const variations = input.variations ?? {};

  return {
    enhance: {
      role: sanitizeString(enhance.role, 'enhance.role'),
      task: sanitizeString(enhance.task, 'enhance.task'),
      personaTemplate: sanitizeString(
        enhance.personaTemplate,
        'enhance.personaTemplate',
      ),
      rules: sanitizeStringArray(enhance.rules, 'enhance.rules'),
      categoryLineTemplate: sanitizeString(
        enhance.categoryLineTemplate,
        'enhance.categoryLineTemplate',
      ),
      toneLineTemplate: sanitizeString(
        enhance.toneLineTemplate,
        'enhance.toneLineTemplate',
      ),
      closingInstruction: sanitizeString(
        enhance.closingInstruction,
        'enhance.closingInstruction',
      ),
    },
    variations: {
      intro: sanitizeString(variations.intro, 'variations.intro'),
      styles: sanitizeStringArray(variations.styles, 'variations.styles'),
      categoryLineTemplate: sanitizeString(
        variations.categoryLineTemplate,
        'variations.categoryLineTemplate',
      ),
      outputInstruction: sanitizeString(
        variations.outputInstruction,
        'variations.outputInstruction',
      ),
      exampleOutput: sanitizeString(
        variations.exampleOutput,
        'variations.exampleOutput',
      ),
    },
  };
}

function createSystemPromptStore(db) {
  const docRef = db.collection(SYSTEM_PROMPTS_COLLECTION).doc(SYSTEM_PROMPTS_DOCUMENT);

  async function getSystemPrompts() {
    const snapshot = await docRef.get();
    if (!snapshot.exists) {
      return DEFAULT_SYSTEM_PROMPTS;
    }

    return mergeObjects(DEFAULT_SYSTEM_PROMPTS, snapshot.data());
  }

  async function saveSystemPrompts(input) {
    const validated = validateSystemPrompts(input);
    await docRef.set(
      {
        ...validated,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
    return validated;
  }

  return {
    getSystemPrompts,
    saveSystemPrompts,
    defaultSystemPrompts: DEFAULT_SYSTEM_PROMPTS,
  };
}

export { createSystemPromptStore, DEFAULT_SYSTEM_PROMPTS };
