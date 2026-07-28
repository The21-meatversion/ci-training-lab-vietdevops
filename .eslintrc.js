'use strict';

module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 2021,
  },
  rules: {
    semi: ['error', 'always'],
    'no-unused-vars': ['error', { vars: 'all', args: 'after-used' }],
    eqeqeq: ['error', 'always'],
    'no-var': 'error',
    'prefer-const': 'error',
    'no-console': 'warn',
  },
};
