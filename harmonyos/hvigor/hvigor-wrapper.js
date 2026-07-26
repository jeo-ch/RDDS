// ----------------------------------------------------------------------------
//  Hvigor wrapper script
//  Bootstraps the hvigor build system by downloading the hvigor npm package
//  if not yet installed, then runs the user's hvigorfile.ts.
// ----------------------------------------------------------------------------
'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const HVIGOR_CONFIG = 'hvigor-config.json5';
const HVIGOR_VERSION_CACHE = 'hvigor/hvigor-wrapper.cache';

function getProjectRoot() {
  let dir = __dirname;
  while (true) {
    if (fs.existsSync(path.join(dir, 'oh-package.json5')) ||
        fs.existsSync(path.join(dir, 'build-profile.json5'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return __dirname;
    }
    dir = parent;
  }
}

function readConfig() {
  const cfgPath = path.join(__dirname, HVIGOR_CONFIG);
  if (!fs.existsSync(cfgPath)) {
    console.error(`Error: ${HVIGOR_CONFIG} not found at ${cfgPath}`);
    process.exit(1);
  }
  // JSON5 not parsed here for simplicity; we extract hvigorVersion with regex.
  const content = fs.readFileSync(cfgPath, 'utf-8');
  const m = content.match(/"hvigorVersion"\s*:\s*"([^"]+)"/);
  if (!m) {
    console.error(`Error: hvigorVersion not found in ${HVIGOR_CONFIG}`);
    process.exit(1);
  }
  return { hvigorVersion: m[1] };
}

function ensureHvigorInstalled(projectRoot, hvigorVersion) {
  const hvigorPath = path.join(projectRoot, 'node_modules', '@ohos', 'hvigor');
  const cacheFile = path.join(projectRoot, HVIGOR_VERSION_CACHE);
  let installedVersion = '';
  if (fs.existsSync(cacheFile)) {
    installedVersion = fs.readFileSync(cacheFile, 'utf-8').trim();
  }
  if (installedVersion === hvigorVersion && fs.existsSync(hvigorPath)) {
    return;
  }
  console.log(`Installing @ohos/hvigor@${hvigorVersion} ...`);
  execSync(`npm install --no-save @ohos/hvigor@${hvigorVersion}`, {
    stdio: 'inherit',
    cwd: projectRoot,
  });
  fs.writeFileSync(cacheFile, hvigorVersion);
}

function main() {
  const projectRoot = getProjectRoot();
  const cfg = readConfig();
  ensureHvigorInstalled(projectRoot, cfg.hvigorVersion);

  const hvigorBin = path.join(projectRoot, 'node_modules', '@ohos', 'hvigor', 'bin', 'hvigor.js');
  if (!fs.existsSync(hvigorBin)) {
    console.error(`Error: hvigor.js not found at ${hvigorBin}`);
    process.exit(1);
  }

  // Forward all args to hvigor.js
  const args = process.argv.slice(2);
  const child = require('child_process').spawnSync(
    process.execPath,
    [hvigorBin, '-p', projectRoot].concat(args),
    { stdio: 'inherit', cwd: projectRoot }
  );
  process.exit(child.status || 0);
}

main();
