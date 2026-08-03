import Anthropic from '@anthropic-ai/sdk';
import 'dotenv/config';
import { getAppConfig } from '../config/appConfig.js';
import { db } from '../config/firebaseAdmin.js';
import { createSystemPromptStore } from './systemPrompts.js';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY,
});

const systemPromptStore = createSystemPromptStore(db);

const MODEL_CONFIG = {
  premium: 'claude-sonnet-4-5',
  free: 'claude-sonnet-4-5',
};

const categoryInstructions = {
  General:
    'Create a clear, specific, and well-structured prompt for any AI assistant.',
  'Image Generation':
    'Create a detailed image generation prompt optimized for tools like Midjourney, DALL-E, or Stable Diffusion. Include style, lighting, composition, mood, and technical details.',
  Coding:
    'Create a precise coding prompt that includes the programming language, desired functionality, expected inputs/outputs, and any constraints or preferences.',
  Writing:
    'Create a comprehensive writing prompt that specifies tone, audience, format, length, style, and key points to cover.',
  Business:
    'Create a professional business prompt that is formal, specific, includes context, desired outcomes, and any relevant constraints.',
};

const AI_TOOL_INSTRUCTIONS = {
  Cursor: `This prompt will be used in Cursor AI code editor. Additionally optimize for:
- Referencing existing codebase context
- TypeScript best practices
- Component level specificity
- Mentioning relevant files to create or edit
- Following existing project patterns`,
  'Claude Code': `This prompt will be used in Claude Code CLI terminal tool. Additionally optimize for:
- Terminal and CLI context
- File system operations clarity
- Step by step implementation instructions
- Bash commands where relevant
- Clear scope of changes needed`,
  'GitHub Copilot': `This prompt will be used with GitHub Copilot. Additionally optimize for:
- Inline code completion context
- Function and method level specificity
- Language specific patterns and conventions
- Clear input and output expectations
- Docstring and comment style guidance`,
  'Bolt/Lovable': `This prompt will be used in Bolt or Lovable AI app builder. Additionally optimize for:
- Full stack application context
- UI component descriptions with styling
- Database schema requirements
- Authentication and authorization needs
- Deployment ready production code
- Supabase or Firebase backend patterns`,
  ChatGPT: `This prompt will be used in ChatGPT. Additionally optimize for:
- Clear role assignment at the start
- Step by step numbered instructions
- Specific output format requirements
- Example inputs and outputs
- Language and framework specification`,
  Gemini: `This prompt will be used in Google Gemini. Additionally optimize for:
- Structured clear task description
- Formatted output requirements
- Specific technical constraints
- Google ecosystem awareness
- Multimodal context if relevant`,
};

const toneInstructions = {
  Auto: '',
  Professional: 'Use a formal, professional tone throughout the prompt.',
  Creative:
    'Use an imaginative, creative tone that encourages unique and artistic outputs.',
  Casual:
    'Use a friendly, conversational tone that feels approachable and relaxed.',
  Persuasive:
    'Use a compelling, persuasive tone designed to convince or influence.',
  Technical:
    'Use precise technical language appropriate for expert-level understanding.',
};

function normalizeCategory(category = 'General') {
  const aliases = {
    general: 'General',
    General: 'General',
    coding: 'Coding',
    Coding: 'Coding',
    writing: 'Writing',
    Writing: 'Writing',
    business: 'Business',
    Business: 'Business',
    image: 'Image Generation',
    Image: 'Image Generation',
    'image-generation': 'Image Generation',
    'Image Generation': 'Image Generation',
  };
  if (aliases[category]) {
    return aliases[category];
  }

  const categories = getAppConfig().categories;
  const match = categories.find(
    (item) => item.id === category || item.label === category,
  );
  return aliases[match?.label] || aliases[match?.id] || match?.label || category || 'General';
}

function normalizeTone(tone = 'Auto') {
  const tones = getAppConfig().tones;
  const match = tones.find((item) => item.id === tone || item.label === tone);
  return match?.label || tone || 'Auto';
}

function normalizeAiTool(aiTool = 'Cursor') {
  const aliases = {
    'Bolt / Lovable': 'Bolt/Lovable',
  };
  if (aliases[aiTool]) {
    return aliases[aiTool];
  }

  const supportedTools = Object.keys(AI_TOOL_INSTRUCTIONS);
  return supportedTools.includes(aiTool) ? aiTool : 'Cursor';
}

function isRetryableAnthropicError(error) {
  const status = error?.status || error?.statusCode || error?.cause?.status;
  return status === 429 || status === 529;
}

function createUpstreamBusyError() {
  const error = new Error(
    'The AI service is busy right now. Please try again in a moment.',
  );
  error.status = 503;
  error.code = 'upstream-busy';
  return error;
}

async function runAnthropicRequest(requestFactory) {
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await requestFactory();
    } catch (error) {
      if (!isRetryableAnthropicError(error) || attempt === maxAttempts) {
        console.error(
          'Anthropic request failed:',
          error?.status || error?.statusCode,
          error?.message,
        );
        if (isRetryableAnthropicError(error)) {
          throw createUpstreamBusyError();
        }
        throw error;
      }

      const delayMs = 400 * attempt;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }

  throw createUpstreamBusyError();
}

async function getSystemPrompt(category, tone = 'Auto', persona = null) {
  const resolvedCategory = normalizeCategory(category);
  const resolvedTone = normalizeTone(tone);
  const promptConfig = await systemPromptStore.getSystemPrompts();

  let personaContext = '';
  if (persona && persona.trim()) {
    personaContext = `\n\n${promptConfig.enhance.personaTemplate.replace('{{persona}}', persona.trim())}`;
  }

  let toneInstruction = '';
  if (resolvedTone && resolvedTone !== 'Auto' && toneInstructions[resolvedTone]) {
    toneInstruction = `\n\n${promptConfig.enhance.toneLineTemplate.replace('{{toneInstruction}}', toneInstructions[resolvedTone])}`;
  }

  const rules = promptConfig.enhance.rules
    .map((rule, index) => `${index + 1}. ${rule}`)
    .join('\n');
  const categoryLine = promptConfig.enhance.categoryLineTemplate
    .replace('{{category}}', resolvedCategory)
    .replace(
      '{{instruction}}',
      categoryInstructions[resolvedCategory] || categoryInstructions.General,
    );

  return `${promptConfig.enhance.role}
${personaContext}
${promptConfig.enhance.task}

STRICT RULES:
${rules}
${promptConfig.enhance.rules.length + 1}. ${categoryLine}${toneInstruction}

${promptConfig.enhance.closingInstruction}`;
}

function createSpecialistPrompt(category, aiTool) {
  switch (category) {
    case 'Coding':
      return `You are a Senior Software Engineer with 10+ years of experience across multiple frameworks and languages. You have deep expertise in writing prompts that get AI coding tools to produce clean, working, production-ready code.

When enhancing a coding prompt you always:
- Infer the best programming language, framework, and architecture when the user does not know them
- Specify the exact programming language and framework when they are known
- Define clear acceptance criteria
- Include error handling requirements
- Mention performance considerations
- Specify coding style preferences
- Break complex tasks into clear steps
- Include relevant context about what already exists
- Mention files or components that need to be created or modified
- Specify testing requirements where relevant
- Translate non-technical user goals into technically precise implementation instructions

${AI_TOOL_INSTRUCTIONS[aiTool]}

Transform the rough input into a precise, detailed coding prompt that will get working code on the first try, even when the user is non-technical.`;
    case 'Writing':
      return `You are a world class copywriter and content strategist with 15+ years experience writing for top global brands, publications and media companies. You have deep expertise in crafting prompts that produce compelling, engaging, professional written content.

When enhancing a writing prompt you always:
- Define the target audience specifically
- Specify the tone (professional/casual/inspiring/urgent)
- Define the format (blog post/email/caption/essay/script)
- Set the desired length and structure
- Include the core message or argument to convey
- Specify the call to action if needed
- Define the reading level and vocabulary style
- Include SEO keywords if relevant
- Mention brand voice guidelines if applicable
- Specify what emotion to evoke in the reader

Transform the rough input into a detailed writing brief that will produce publish-ready professional content.`;
    case 'Image Generation':
      return `You are an expert AI image prompt artist with deep mastery of Midjourney, DALL-E 3, Stable Diffusion and Adobe Firefly. You know exactly which keywords, styles, lighting terms and technical parameters produce stunning images.

When enhancing an image generation prompt you always:
- Describe the subject in precise visual detail
- Specify the art style (photorealistic/illustration/oil painting/digital art/cinematic etc.)
- Define the lighting (golden hour/studio lighting/dramatic shadows/soft diffused light etc.)
- Specify the camera angle and composition (aerial view/close up/wide shot/portrait etc.)
- Add mood and atmosphere descriptors
- Include color palette or dominant colors
- Reference similar artists or visual styles where appropriate
- Add technical quality tags (8k/ultra detailed/sharp focus/high fidelity etc.)
- Specify aspect ratio if relevant
- Add negative prompts for what to avoid

Transform the rough input into a rich, detailed image generation prompt that will produce stunning, precise visual results.`;
    case 'Business':
      return `You are a senior business consultant with an MBA from a top institution and 20+ years experience advising Fortune 500 companies, startups and entrepreneurs on strategy, marketing, operations and growth. You craft prompts that produce professional, actionable business content.

When enhancing a business prompt you always:
- Define the business context and industry
- Specify the target stakeholder or audience
- Include relevant business metrics or KPIs
- Define the desired outcome or deliverable
- Specify the format (report/presentation/strategy/plan/email/proposal etc.)
- Include competitive context where relevant
- Define the tone (formal/executive/persuasive)
- Specify any constraints (budget/timeline/resources)
- Include success criteria
- Request data driven recommendations where applicable

Transform the rough input into a precise professional business prompt that will produce executive quality output.`;
    case 'General':
    default:
      return `You are a world class prompt engineer with deep expertise in getting the absolute best results from every major AI model including ChatGPT, Claude, Gemini and others.

When enhancing a general prompt you always:
- Add a clear role or persona for the AI to adopt
- Define the task with maximum specificity
- Include relevant context and background
- Specify the desired output format
- Define the tone and style
- Add constraints and requirements
- Include examples of desired output where helpful
- Break complex requests into clear steps
- Specify what to avoid or exclude
- Define success criteria for the output

Transform the rough input into a masterfully crafted prompt that will produce exceptional results from any AI model.`;
  }
}

function appendToolInstructionIfNeeded(systemPrompt, category, aiTool) {
  if (category === 'Coding') {
    return systemPrompt;
  }

  if (aiTool === 'ChatGPT' || aiTool === 'Gemini') {
    return `${systemPrompt}\n\n${AI_TOOL_INSTRUCTIONS[aiTool]}`;
  }

  return systemPrompt;
}

function appendPersonaAndTone(systemPrompt, tone, persona) {
  let result = systemPrompt;

  if (persona && persona.trim()) {
    result += `\n\nAdditional user context:\n- The user describes themselves as: ${persona.trim()}`;
  }

  if (tone && tone !== 'Auto' && toneInstructions[tone]) {
    result += `\n\nTone requirement:\n- ${toneInstructions[tone]}`;
  }

  result += '\n\nReturn only the final enhanced prompt, ready to paste into the target AI tool.';

  return result;
}

async function enhancePrompt(
  roughPrompt,
  category = 'General',
  isPremium = false,
  tone = 'Auto',
  persona = null,
  aiTool = 'Cursor',
) {
  const resolvedCategory = normalizeCategory(category);
  const resolvedTone = normalizeTone(tone);
  const resolvedAiTool = normalizeAiTool(aiTool);
  const model = isPremium ? MODEL_CONFIG.premium : MODEL_CONFIG.free;
  const systemPrompt = appendPersonaAndTone(
    appendToolInstructionIfNeeded(
      createSpecialistPrompt(resolvedCategory, resolvedAiTool),
      resolvedCategory,
      resolvedAiTool,
    ),
    resolvedTone,
    persona,
  );

  console.log(
    `Using model: ${model} (isPremium: ${isPremium}, category: ${resolvedCategory}, tone: ${resolvedTone}, aiTool: ${resolvedAiTool})`,
  );

  const message = await runAnthropicRequest(() =>
    anthropic.messages.create({
      model,
      max_tokens: 1024,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: roughPrompt.trim(),
        },
      ],
    }),
  );

  const textBlock = message.content.find((block) => block.type === 'text');
  if (textBlock) {
    return textBlock.text;
  }

  throw new Error('No text content in Claude response');
}

async function generateVariations(
  roughPrompt,
  category = 'General',
  isPremium = false,
) {
  const model = isPremium ? MODEL_CONFIG.premium : MODEL_CONFIG.free;
  const resolvedCategory = normalizeCategory(category);
  const promptConfig = await systemPromptStore.getSystemPrompts();

  console.log(`Generating variations with model: ${model}`);

  const styleLines = promptConfig.variations.styles
    .map((style, index) => `${index + 1}. ${style}`)
    .join('\n');
  const categoryLine = promptConfig.variations.categoryLineTemplate
    .replace('{{category}}', resolvedCategory)
    .replace(
      '{{instruction}}',
      categoryInstructions[resolvedCategory] || categoryInstructions.General,
    );

  const systemPrompt = `${promptConfig.variations.intro}

${styleLines}

${categoryLine}

${promptConfig.variations.outputInstruction}
${promptConfig.variations.exampleOutput}`;

  const message = await runAnthropicRequest(() =>
    anthropic.messages.create({
      model,
      max_tokens: 2048,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: roughPrompt.trim(),
        },
      ],
    }),
  );

  const textBlock = message.content.find((block) => block.type === 'text');
  if (!textBlock) {
    throw new Error('No text content in Claude response');
  }

  try {
    let responseText = textBlock.text.trim();

    if (responseText.startsWith('```')) {
      responseText = responseText
        .replace(/```json?\n?/g, '')
        .replace(/```/g, '')
        .trim();
    }

    const variations = JSON.parse(responseText);

    if (!Array.isArray(variations) || variations.length !== 3) {
      throw new Error('Invalid response format');
    }

    return variations;
  } catch (error) {
    console.error('Failed to parse variations:', error);
    throw new Error('Failed to generate valid variations');
  }
}

export { enhancePrompt, generateVariations };
