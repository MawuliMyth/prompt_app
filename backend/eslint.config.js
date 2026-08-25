import js from '@eslint/js';
import globals from 'globals';

// Minimal ESLint setup - the backend previously had no lint tooling at all,
// unlike the Flutter side (analysis_options.yaml). This intentionally
// starts small (recommended rules + a few correctness rules relevant to
// this codebase's async/Express style) rather than importing a large
// opinionated config, so it's easy to extend later.
export default [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'module',
      globals: {
        ...globals.node,
      },
    },
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-console': 'off',
      'require-await': 'warn',
      'no-return-await': 'warn',
    },
  },
  {
    files: ['test/**'],
    rules: {
      // Test doubles are declared async for interface-shape consistency
      // with the real DI-injected implementations, even when a given
      // fake doesn't need to await anything internally.
      'require-await': 'off',
    },
  },
  {
    ignores: ['node_modules/', 'public/'],
  },
];
