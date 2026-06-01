const fs   = require('fs');
const path = require('path');
const crypto = require('crypto');

const BASE = 'C:/Project ITY/assets/characters';
const CHARS = ['cyclone', 'vector'];

// Godot UID karakterleri (base58 benzeri)
const UID_CHARS = 'abcdefghijklmnopqrstuvwxyz0123456789';
function genUid() {
  let s = '';
  for (let i = 0; i < 13; i++) s += UID_CHARS[Math.floor(Math.random() * UID_CHARS.length)];
  return s;
}

for (const char of CHARS) {
  const sheetsDir = path.join(BASE, char, 'sheets');
  const files = fs.readdirSync(sheetsDir).filter(f => f.endsWith('.png') && !f.endsWith('.import'));

  for (const file of files) {
    const importPath = path.join(sheetsDir, file + '.import');
    if (fs.existsSync(importPath)) continue;

    const resSrc  = `res://assets/characters/${char}/sheets/${file}`;
    const hash    = crypto.createHash('md5').update(resSrc).digest('hex');
    const ctexName = `${file}-${hash}.ctex`;
    const uid     = genUid();

    const content = `[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://${uid}"
path="res://.godot/imported/${ctexName}"
metadata={
"vram_texture": false
}

[deps]

source_file="${resSrc}"
dest_files=["res://.godot/imported/${ctexName}"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
`;
    fs.writeFileSync(importPath, content);
    console.log(`  ${file}.import`);
  }
}
console.log('Done!');
