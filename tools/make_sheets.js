const { Jimp } = require('C:/Users/emrek/AppData/Roaming/npm/node_modules/jimp');
const fs = require('fs');
const path = require('path');

const CHARS_DIR = 'C:/Project ITY/assets/characters';
const DIRS = ['east', 'north-east', 'north', 'north-west', 'west', 'south-west', 'south', 'south-east'];
const DIR_MAP = { 'east':'E', 'north-east':'NE', 'north':'N', 'north-west':'NW', 'west':'W', 'south-west':'SW', 'south':'S', 'south-east':'SE' };

// Cyclone animations
const CYCLONE_ANIMS = [
  { folder: 'Fight_Stance_Idle-cb251d6c', key: 'idle' },
  { folder: 'Running-79891197',           key: 'run'  },
];

// Vector animations
const VECTOR_ANIMS = [
  { folder: 'Breathing_Idle-37f7a221', key: 'idle' },
  { folder: 'animation-2a10ab16',      key: 'run'  },
];

async function makeSheet(charName, animFolder, animKey, dirFolder, dirCode) {
  const frameDir = path.join(CHARS_DIR, charName, 'animations', animFolder, dirFolder);
  const files = fs.readdirSync(frameDir)
    .filter(f => f.endsWith('.png') && !f.endsWith('.import'))
    .sort();

  if (files.length === 0) return;

  const frames = [];
  for (const f of files) {
    const img = await Jimp.read(path.join(frameDir, f));
    frames.push(img);
  }

  const fw = frames[0].bitmap.width;
  const fh = frames[0].bitmap.height;
  const sheet = new Jimp({ width: fw * frames.length, height: fh, color: 0x00000000 });
  for (let i = 0; i < frames.length; i++) {
    sheet.composite(frames[i], i * fw, 0);
  }

  const outDir = path.join(CHARS_DIR, charName, 'sheets');
  fs.mkdirSync(outDir, { recursive: true });
  const outName = `${charName}_${animKey}_${dirCode}.png`;
  await sheet.write(path.join(outDir, outName));
  console.log(`  -> ${outName} (${frames.length} frames, ${fw}x${fh})`);
}

async function processChar(charName, anims) {
  console.log(`\n=== ${charName} ===`);
  for (const anim of anims) {
    for (const d of DIRS) {
      await makeSheet(charName, anim.folder, anim.key, d, DIR_MAP[d]);
    }
  }
}

(async () => {
  await processChar('cyclone', CYCLONE_ANIMS);
  await processChar('vector',  VECTOR_ANIMS);
  console.log('\nDone!');
})();
