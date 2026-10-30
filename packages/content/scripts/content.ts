// Content tooling.
//   validate  validate every pack, regenerate schema/pack.schema.json (for editor autocompletion)
//             and fail if the schema or the mobile copy of the packs is stale (`--check` in CI)
//   sync      copy packs into apps/mobile/assets/content/
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';
import { packSchema } from '../src/schema.ts';
import { validatePack } from '../src/validate.ts';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const packsDir = join(root, 'packs');
const schemaPath = join(root, 'schema/pack.schema.json');
const mobileDir = join(root, '../../apps/mobile/assets/content');
const [command] = process.argv.slice(2);
const packFiles = readdirSync(packsDir).filter((f) => f.endsWith('.json')).sort();

function validate(): boolean {
  let ok = true;
  for (const file of packFiles) {
    const result = validatePack(JSON.parse(readFileSync(join(packsDir, file), 'utf8')));
    if (result.ok) {
      const cats = result.pack.categories.length;
      console.log(`✓ ${file}: ${result.pack.items.length} items in ${cats} categories`);
    } else {
      ok = false;
      console.error(`✗ ${file}`);
      for (const e of result.errors) console.error(`  - ${e}`);
    }
  }

  const schema = JSON.stringify(z.toJSONSchema(packSchema, { io: 'input' }), null, 2) + '\n';
  const current = existsSync(schemaPath) ? readFileSync(schemaPath, 'utf8') : '';
  if (current !== schema) {
    mkdirSync(dirname(schemaPath), { recursive: true });
    writeFileSync(schemaPath, schema);
    console.log('Updated schema/pack.schema.json');
  }

  for (const file of packFiles) {
    const copy = join(mobileDir, file);
    if (!existsSync(copy) || readFileSync(copy, 'utf8') !== readFileSync(join(packsDir, file), 'utf8')) {
      ok = false;
      console.error(`apps/mobile/assets/content/${file} is stale. Run \`pnpm content:sync\`.`);
    }
  }
  return ok;
}

if (command === 'validate') {
  if (!validate()) process.exit(1);
} else if (command === 'sync') {
  mkdirSync(mobileDir, { recursive: true });
  for (const file of packFiles) copyFileSync(join(packsDir, file), join(mobileDir, file));
  console.log(`Copied ${packFiles.length} pack(s) to apps/mobile/assets/content/`);
} else {
  console.error('Usage: content.ts validate|sync');
  process.exit(2);
}
