// eslint.config.js
import eslint from '@eslint/js'
import tseslint from 'typescript-eslint'
import prettierRecommended from 'eslint-plugin-prettier/recommended'

export default [
  {
    ignores: ['dist/**', 'node_modules/**', '**/*.d.ts', 'coverage/**'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
    extends: [eslint.configs.recommended, 'plugin:security/recommended'],
    rules: {
      'no-unused-vars': 'error',
      'no-console': 'warn',
      'promise/prefer-await-to-then': 'error',
    },
  },
  // TypeScript files
  tseslint.config(
    {
      ignores: [],
    },
    prettierRecommended,
    tseslint.configs.recommended,
    {
      files: ['**/*.ts'],
      parser: tseslint.parser,
      parserOptions: { project: './tsconfig.json' },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
      },
    }
  ),
]

