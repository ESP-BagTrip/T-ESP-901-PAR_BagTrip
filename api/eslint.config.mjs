// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import promise from 'eslint-plugin-promise';

export default [
	// ESLint recommended base
	eslint.configs.recommended,
	// Project-wide settings
	{
		ignores: ['dist/**', 'node_modules/**', '**/*.d.ts', 'coverage/**'],
		languageOptions: {
			ecmaVersion: 'latest',
			sourceType: 'module',
		},
		plugins: { promise },
		rules: {
			'no-unused-vars': 'error',
			'no-console': 'warn',
			'promise/prefer-await-to-then': 'error',
		},
	},
	// TypeScript configs
	...tseslint.config(
		{
			ignores: [],
		},
		tseslint.configs.recommended,
		{
			files: ['**/*.ts'],
			languageOptions: {
				parser: tseslint.parser,
				parserOptions: { project: './tsconfig.json' },
			},
			rules: {
				'@typescript-eslint/no-explicit-any': 'off',
			},
		}
	),
	// Prettier last to turn off formatting conflicts
	prettierRecommended,
];


