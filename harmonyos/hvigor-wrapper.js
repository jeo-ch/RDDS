const process = require('process');
const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');

let hvigorHome = path.join(__dirname, '.hvigor');
let hvigorVersion = '5.0.4';
let hvigorJar = path.join(hvigorHome, 'hvigor-wrapper', hvigorVersion, 'hvigor-wrapper-'.concat(hvigorVersion, '.jar'));

function download() {
  const hvigorUrl = 'https://repo.huaweicloud.com/repository/harmonyos-cn/com/huawei/ohos/hvigor-wrapper/'.concat(hvigorVersion, '/hvigor-wrapper-').concat(hvigorVersion, '.jar');
  console.log('Downloading: '.concat(hvigorUrl));
  
  if (!fs.existsSync(path.dirname(hvigorJar))) {
    fs.mkdirSync(path.dirname(hvigorJar), { recursive: true });
  }
  
  const curlCmd = 'curl -L -o '.concat(hvigorJar, ' ').concat(hvigorUrl);
  try {
    execSync(curlCmd, { stdio: 'inherit' });
    console.log('Download completed: '.concat(hvigorJar));
    return true;
  } catch (error) {
    console.error('Failed to download hvigor: '.concat(error.message));
    return false;
  }
}

function run() {
  if (!fs.existsSync(hvigorJar)) {
    if (!download()) {
      process.exit(1);
    }
  }
  
  const javaHome = process.env.JAVA_HOME;
  let javaCmd = 'java';
  if (javaHome) {
    javaCmd = path.join(javaHome, 'bin', 'java');
  }
  
  const classpath = [hvigorJar].join(path.delimiter);
  const args = [
    '-classpath',
    classpath,
    'com.huawei.ohos.hvigor.wrapper.HvigorWrapperMain'
  ].concat(process.argv.slice(2));
  
  try {
    execSync(''.concat(javaCmd, ' ').concat(args.join(' ')), {
      cwd: __dirname,
      stdio: 'inherit'
    });
  } catch (error) {
    console.error('Execution failed: '.concat(error.message));
    process.exit(1);
  }
}

run();
