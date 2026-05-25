shader_type canvas_item;

void fragment() {
    vec2 uv = UV;
    vec4 color = texture(TEXTURE, uv);
    
    // Vignette efekti
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    float vignette = smoothstep(0.8, 0.3, dist);
    
    // Cyberpunk renk tonu (hafif cyan/mavi)
    color.rgb *= vec3(0.85, 0.95, 1.1);
    
    // Vignette uygula
    color.rgb *= vignette;
    color.a = 1.0 - vignette;
    color.a = clamp(1.0 - vignette * 0.5, 0.0, 1.0);
    
    COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vignette);
}