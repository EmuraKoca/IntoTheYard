shader_type canvas_item;

// Ekran dokusunu yakalar (CanvasLayer çizilmeden önceki oyun sahnesi)
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	// textureLod: mipmap seviyesi 3.0 ≈ ~8px efektif bulanıklık yarıçapı
	// filter_linear_mipmap sayesinde GPU mipmapları otomatik üretir, tek örnekle kaliteli blur
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, 3.0);

	// Hafif renk soluklaştırma (saturasyon azalt) — dondurulmuş/moody his
	float luma = dot(blurred.rgb, vec3(0.299, 0.587, 0.114));
	blurred.rgb = mix(blurred.rgb, vec3(luma), 0.22);

	// Hafif siber-punk cyan tonu
	blurred.rgb *= vec3(0.88, 0.94, 1.10);

	COLOR = blurred;
}
