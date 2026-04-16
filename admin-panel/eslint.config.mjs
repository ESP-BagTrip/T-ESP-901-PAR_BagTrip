import { FlatCompat } from '@eslint/eslintrc'
import { dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const compat = new FlatCompat({ baseDirectory: __dirname })

const config = [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  {
    ignores: [
      '**/*.test.ts',
      '**/*.test.tsx',
      'src/__tests__/**',
    ],
  },
]

export default config
