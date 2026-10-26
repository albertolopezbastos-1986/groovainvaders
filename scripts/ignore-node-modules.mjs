import { writeFileSync, mkdirSync } from 'node:fs';
mkdirSync('node_modules', { recursive: true });
writeFileSync('node_modules/.gdignore', '');
