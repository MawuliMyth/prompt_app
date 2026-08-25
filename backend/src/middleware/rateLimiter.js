import { createError, getClientIp } from '../services/accessControl.js';

const buckets = new Map();

// This limiter is in-process and unbounded unless we prune it: every
// distinct key (keyPrefix + client IP) sticks around forever otherwise. As
// long as getClientIp() reflects the real connection (see accessControl.js)
// the key space is bounded by real distinct clients, but we still sweep
// periodically so long-running processes don't accumulate stale entries
// from IPs that stopped sending requests.
const SWEEP_INTERVAL_MS = 10 * 60 * 1000;
const MAX_ENTRY_AGE_MS = 60 * 60 * 1000;
let lastSweep = Date.now();

function sweepBuckets(now) {
  for (const [key, timestamps] of buckets.entries()) {
    const recent = timestamps.filter((timestamp) => now - timestamp < MAX_ENTRY_AGE_MS);
    if (recent.length === 0) {
      buckets.delete(key);
    } else {
      buckets.set(key, recent);
    }
  }
}

function createRateLimiter({ keyPrefix, windowMs, maxRequests }) {
  return (req, res, next) => {
    const now = Date.now();

    if (now - lastSweep > SWEEP_INTERVAL_MS) {
      sweepBuckets(now);
      lastSweep = now;
    }

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
