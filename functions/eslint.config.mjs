import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['lib/**', 'node_modules/**', 'src/shared/constants.ts'] },
  ...tseslint.configs.recommended,
);
