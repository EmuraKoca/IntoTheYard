shader_type canvas_item;

// Bu shader CanvasLayer'ın en üstüne bindirilir.
// screen_texture, kendi draw çağrısından ÖNCE render edilmiş her şeyi (blur + panel + kartlar) yakalar.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// GDScript tarafından Tween ile 1.0 → 0.0'a çekilir
uniform float glitch_strength : hint_range(0.0, 1.0) = 1.0;

// Basit hash — shader içi rastlantısallık için
float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float g = glitch_strength;

	// Güç sıfıra ulaşınca hiç çizme → verimli geçiş
	if (g <= 0.004) {
		discard;
	}

	float t = TIME;

	// ── Yatay tarama-blok kayması ──────────────────────────────────────────
	// Ekranı 25 yatay bandına böl; her bant ayrı bir zaman dilimiyle tetiklenir
	float block_y  = floor(SCREEN_UV.y * 25.0) / 25.0;
	float trigger  = step(0.80, rand(vec2(block_y, floor(t * 11.0))));
	float noise_x  = rand(vec2(block_y, floor(t * 17.0))) * 2.0 - 1.0;
	float shift    = noise_x * 0.038 * g * trigger;

	// ── RGB kanal ayrışması (Chromatic Aberration) ─────────────────────────
	float ca = 0.008 * g;
	float r  = texture(screen_texture, SCREEN_UV + vec2(shift + ca,  0.0)).r;
	float gr = texture(screen_texture, SCREEN_UV + vec2(shift,       0.0)).g;
	float b  = texture(screen_texture, SCREEN_UV + vec2(shift - ca,  0.0)).b;
	vec3 col = vec3(r, gr, b);

	// ── Anlık parlak yatay çizgiler (siber-punk flash) ─────────────────────
	float hline = step(0.984, rand(vec2(floor(SCREEN_UV.y * 350.0), floor(t * 28.0))));
	col += vec3(0.0, 1.0, 0.92) * hline * 0.45 * g;

	// ── Dikey blok titremesi (ara sıra tek bir satır ters döner) ──────────
	float vblock  = step(0.96, rand(vec2(0.0, floor(t * 7.0))));
	float flip_uv = mix(SCREEN_UV.y, 1.0 - SCREEN_UV.y, vblock * 0.25 * g);
	vec3 stutter  = texture(screen_texture, vec2(SCREEN_UV.x + shift, flip_uv)).rgb;
	col = mix(col, stutter, vblock * g * 0.35);

	// Alpha = glitch_strength → Tween ile 1.0'dan 0.0'a solar, orijinal UI görünür hâle gelir
	COLOR = vec4(col, g);
}
