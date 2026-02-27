import Groq from 'groq-sdk';
import 'dotenv/config';

const groq = new Groq();

/**
 * Transcribe audio using Groq Whisper API
 * @param {Buffer} audioBuffer - Audio file buffer
 * @param {string} filename - Original filename with extension
 * @returns {Promise<string>} - Transcribed text
 */
async function transcribeAudio(audioBuffer, filename = 'audio.webm') {
  // Determine content type based on file extension
  const ext = filename.toLowerCase().split('.').pop();
  const contentTypes = {
    'webm': 'audio/webm',
    'mp3': 'audio/mpeg',
    'mp4': 'audio/mp4',
    'mpeg': 'audio/mpeg',
    'mpga': 'audio/mpeg',
    'm4a': 'audio/m4a',
    'wav': 'audio/wav',
    'oga': 'audio/ogg',
    'ogg': 'audio/ogg',
    'aac': 'audio/aac'
  };

  const contentType = contentTypes[ext] || 'audio/webm';

  // Create a File object from the buffer
  const file = new File([audioBuffer], filename, { type: contentType });

  const transcription = await groq.audio.transcriptions.create({
    file: file,
    model: 'whisper-large-v3-turbo',
    language: 'en',
    response_format: 'json',
  });

  return transcription.text;
}

export { transcribeAudio };
