shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.82, 0.85, 0.87); // Pale bluish-gray
uniform float noise_strength = 0.04;
uniform float pattern_scale = 40.0;
uniform float brightness_variation = 0.02;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float smooth_noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.0) {
		discard;
	}

	vec2 uv = UV * pattern_scale;

	// Subtle wallpaper bump variation
	float n = smooth_noise(uv);
	float brightness = 1.0 + (n - 0.5) * brightness_variation;

	// Very light paper texture noise
	float micro_noise = (random(uv * 100.0) - 0.5) * noise_strength;

	vec3 color = base_color * brightness + micro_noise;

	COLOR = vec4(color, tex.a);
}