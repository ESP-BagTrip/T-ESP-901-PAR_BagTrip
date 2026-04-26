import nextCoreWebVitals from 'eslint-config-next/core-web-vitals'
import nextTypescript from 'eslint-config-next/typescript'

const config = [
  {
    ignores: [
      '**/*.test.ts',
      '**/*.test.tsx',
      'src/__tests__/**',
      'coverage/**',
      '.next/**',
      'node_modules/**',
      'cypress/**',
    ],
  },
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    // Next.js 16 enables React Compiler lint rules. Existing components
    // were authored before the React Compiler — downgrade these to warn
    // until the dedicated React Compiler compliance pass (tracked
    // separately).
    rules: {
      'react-hooks/static-components': 'warn',
      'react-hooks/set-state-in-effect': 'warn',
      'react-hooks/refs': 'warn',
      'react-hooks/preserve-manual-memoization': 'warn',
      'react-hooks/immutability': 'warn',
      'react-hooks/incompatible-library': 'warn',
      'react-hooks/purity': 'warn',
      'react-hooks/component-hook-factories': 'warn',
      'react-hooks/error-boundaries': 'warn',
      'react-hooks/globals': 'warn',
      'react-hooks/unsupported-syntax': 'warn',
      'react-hooks/use-memo': 'warn',
      'react-hooks/gating': 'warn',
      'react-hooks/config': 'warn',
      'react-hooks/no-deriving-state-in-effects': 'warn',
    },
  },
  {
    files: ['cypress.config.ts'],
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
    },
  },
]

export default config
