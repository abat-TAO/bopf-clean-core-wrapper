#!/usr/bin/env node
// Renames the objects of this repository before they are imported into an SAP system, for example when
// the project code BFW collides with existing objects there.
//
//   node tools/rename.mjs --code XY [--letter Y] [--from BFW] [--from-letter Z] [--dry-run]
//   node tools/rename.mjs --map renames.json [--dry-run]
//
// --code replaces the project code in all names: ZCL_BFW_ → ZCL_XY_, ZCX_BFW_ → ZCX_XY_, ZIF_BFW_ → ZIF_XY_,
// $ZBFW_ → $ZXY_ and ZBFW_ → ZXY_. --letter changes the customer namespace letter (Z or Y) at the same time.
// --from and --from-letter name the current code and letter, for a repository that was renamed before.
// --map renames single objects; the file maps old names to new names, e.g. {"ZCL_BFW_FACTORY": "ZCL_BFW_FACTORIES"}.
//
// The script rewrites file names and contents in src/ (abapGit files) and the documentation and checks the SAP
// name length limits.

import { existsSync, readdirSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, relative } from 'node:path';

const root = join(dirname(new URL(import.meta.url).pathname), '..');
const sourceFolders = ['src', 'docs'];
const sourceFiles = ['README.md'];
const textExtensions = /\.(abap|xml|json|md)$/;

// Name length limits of SAP objects; transparent tables are checked separately (16 characters)
const lengthLimits = { clas: 30, intf: 30, prog: 40, msag: 20, tabl: 30, ttyp: 30, dtel: 30, doma: 30, devc: 30 };
const databaseTableLimit = 16;

function parseArguments(argv) {
  const options = { dryRun: false, letter: 'Z', from: 'BFW', 'from-letter': 'Z' };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--dry-run') {
      options.dryRun = true;
    } else if (['--code', '--letter', '--from', '--from-letter', '--map'].includes(argument)) {
      options[argument.slice(2)] = argv[index + 1];
      index += 1;
    } else {
      throw new Error(`Unknown argument ${argument}`);
    }
  }
  if (!options.code && !options.map) {
    throw new Error('Pass --code <new project code> or --map <file with old and new names>');
  }
  for (const code of [options.code, options.from].filter(Boolean)) {
    if (!/^[A-Z][A-Z0-9]{0,12}$/i.test(code)) {
      throw new Error('A project code consists of letters and digits and starts with a letter');
    }
  }
  for (const letter of [options.letter, options['from-letter']]) {
    if (!/^[ZY]$/i.test(letter)) {
      throw new Error('The namespace letter is Z or Y');
    }
  }
  return options;
}

// Characters that belong to an ABAP name
const nameCharacter = '[A-Za-z0-9_$]';

function keepCase(original, replacement) {
  return original === original.toLowerCase() ? replacement.toLowerCase() : replacement.toUpperCase();
}

function buildRules(options) {
  const rules = [];
  if (options.map) {
    const renames = JSON.parse(readFileSync(options.map, 'utf8'));
    for (const [oldName, newName] of Object.entries(renames)) {
      rules.push({
        pattern: new RegExp(`(?<!${nameCharacter})${escape(oldName)}(?!${nameCharacter})`, 'gi'),
        replacement: newName,
      });
    }
  }
  if (options.code) {
    const letter = options.letter.toUpperCase();
    const code = options.code.toUpperCase();
    const fromLetter = options['from-letter'].toUpperCase();
    const from = options.from.toUpperCase();
    const prefixes = [
      [`$${fromLetter}${from}_`, `$${letter}${code}_`],
      [`${fromLetter}CL_${from}_`, `${letter}CL_${code}_`],
      [`${fromLetter}CX_${from}_`, `${letter}CX_${code}_`],
      [`${fromLetter}IF_${from}_`, `${letter}IF_${code}_`],
      [`${fromLetter}${from}_`, `${letter}${code}_`],
    ];
    for (const [oldPrefix, newPrefix] of prefixes) {
      // The dollar sign of local packages is part of the name, so $ZBFW_ is not renamed twice
      const lookbehind = oldPrefix.startsWith('$') ? `(?<!${nameCharacter})` : `(?<!${nameCharacter})(?<!\\$)`;
      rules.push({ pattern: new RegExp(`${lookbehind}${escape(oldPrefix)}`, 'gi'), replacement: newPrefix });
    }
  }
  return rules;
}

function escape(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function rename(text, rules) {
  let result = text;
  for (const rule of rules) {
    result = result.replace(rule.pattern, (match) => keepCase(match, rule.replacement));
  }
  return result;
}

function listFiles(folder) {
  if (!existsSync(folder)) {
    return [];
  }
  return readdirSync(folder).flatMap((entry) => {
    const path = join(folder, entry);
    return statSync(path).isDirectory() ? listFiles(path) : [path];
  });
}

function checkLengths(files) {
  const problems = [];
  for (const file of files) {
    const match = /^(.+?)\.(clas|intf|prog|msag|tabl|ttyp|dtel|doma|devc)\.xml$/.exec(basename(file.target));
    if (match) {
      const name = match[1].replace(/#/g, '/');
      const isDatabaseTable = match[2] === 'tabl' && /<TABCLASS>TRANSP<\/TABCLASS>/.test(file.content);
      const limit = isDatabaseTable ? databaseTableLimit : lengthLimits[match[2]];
      if (name.length > limit) {
        problems.push(`${match[2].toUpperCase()} ${name.toUpperCase()} has ${name.length} characters, at most ${limit} are allowed`);
      }
    }
  }
  return problems;
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const rules = buildRules(options);
  const candidates = [
    ...sourceFolders.flatMap((folder) => listFiles(join(root, folder))),
    ...sourceFiles.map((file) => join(root, file)).filter((file) => existsSync(file)),
  ].filter((file) => textExtensions.test(file));

  const files = candidates.map((source) => {
    const original = readFileSync(source, 'utf8');
    const content = rename(original, rules);
    const isAbapGitFile = relative(root, source).startsWith('src');
    const target = isAbapGitFile ? join(dirname(source), rename(basename(source), rules)) : source;
    return { source, target, original, content };
  });

  const targets = new Set(files.map((file) => file.target));
  if (targets.size !== files.length) {
    throw new Error('Two files would get the same name');
  }
  for (const file of files) {
    if (file.target !== file.source && existsSync(file.target) && !files.some((other) => other.source === file.target)) {
      throw new Error(`${relative(root, file.target)} already exists`);
    }
  }
  const problems = checkLengths(files);
  if (problems.length > 0) {
    throw new Error(`Names too long after renaming:\n  ${problems.join('\n  ')}`);
  }

  const changed = files.filter((file) => file.content !== file.original || file.target !== file.source);
  for (const file of changed) {
    const from = relative(root, file.source);
    const to = relative(root, file.target);
    console.log(from === to ? `changed  ${from}` : `renamed  ${from} -> ${to}`);
  }
  console.log(`${changed.length} file(s) ${options.dryRun ? 'would change (dry run)' : 'changed'}`);
  if (options.dryRun) {
    return;
  }
  // Two phases, so that a chain like A -> B and B -> C does not overwrite B
  const moved = changed.filter((file) => file.target !== file.source);
  for (const file of changed) {
    writeFileSync(file.source, file.content);
  }
  for (const file of moved) {
    renameSync(file.source, `${file.source}.renaming`);
  }
  for (const file of moved) {
    renameSync(`${file.source}.renaming`, file.target);
  }
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
