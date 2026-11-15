import { copyFileSync, lstatSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { buildDossier } from './vendor/makefun-roblox.ts';

const botDir = resolve(process.env.MAKEFUN_BOT_DIR ?? '/bot');
const outputDir = resolve(process.env.MAKEFUN_OUTPUT_DIR ?? '/output');
if (botDir === outputDir) throw new Error('MAKEFUN_BOT_DIR and MAKEFUN_OUTPUT_DIR must differ');

function copyTree(source: string, target: string): void {
  const stat = lstatSync(source);
  if (stat.isDirectory()) {
    mkdirSync(target, { recursive: true });
    const entries = readdirSync(source, { withFileTypes: true }).sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
    for (const entry of entries) {
      copyTree(join(source, entry.name), join(target, entry.name));
    }
    return;
  }
  if (!stat.isFile()) throw new Error(`${source} is not a regular file or directory`);
  copyFileSync(source, target);
}

function resetPath(path: string): void {
  rmSync(path, { recursive: true, force: true });
}

function copyFile(name: string): void {
  const source = join(botDir, name);
  if (!lstatSync(source).isFile()) throw new Error(`${source} is not a regular file`);
  const target = join(outputDir, name);
  resetPath(target);
  copyFileSync(source, target);
}

function copyDirectory(name: string): void {
  const source = join(botDir, name);
  if (!lstatSync(source).isDirectory()) throw new Error(`${source} is not a directory`);
  const target = join(outputDir, name);
  resetPath(target);
  copyTree(source, target);
}

mkdirSync(outputDir, { recursive: true });
copyFile('game.rbxl');
copyFile('PLAY.json');
copyDirectory('src');
copyDirectory('screenshots');

const dossier = buildDossier(outputDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 256 * 1024 },
  max_instances: 500_000,
  scripts_max_source_bytes: 8 * 1024 * 1024,
  scripts_max_path_chars: 1_048_576,
});
writeFileSync(join(outputDir, 'dossier.json'), dossier);
