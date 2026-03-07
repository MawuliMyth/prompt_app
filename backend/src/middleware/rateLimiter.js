import { createError, getClientIp } from '../services/accessControl.js';

const buckets = new Map();

function createRateLimiter({ keyPrefix, windowMs, maxRequests }) {
  return (req, res, next) => {
    const now = Date.now();
    const key = `${keyPrefix}:${getClientIp(req)}`;
    const timestamps = buckets.get(key) ?? [];
    const recent = timestamps.filter((timestamp) => now - timestamp < windowMs);

    if (recent.length >= maxRequests) {
      return next(createError(429, 'Too many requests. Please try again shortly.', 'rate-limit-exceeded'));
    }

    recent.push(now);
    buckets.set(key, recent);
    next();
  };
}

export { createRateLimiter };
