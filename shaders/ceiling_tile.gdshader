shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.94, 0.94, 0.93); // Slight off-white
uniform float speckle_density = 200.0;
uniform float speckle_intensity = 0.15;
uniform float speckle_size = 1.0;
uniform float tile_line_width = 0.02;
uniform float tile_spacing = 0.25; // grid spacing in UV units
uniform vec3 tile_line_color = vec3(0.85, 0.85, 0.85);

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;

	// Speckle noise
	float speckle = step(1.0 - speckle_intensity, random(uv * speckle_density));

	// Tile lines
	vec2 tile_uv = fract(uv / tile_spacing);
	float line_mask = step(tile_uv.x, tile_line_width) + step(tile_uv.y, tile_line_width);

	vec3 color = base_color;

	// Apply tile line color
	color = mix(color, tile_line_color, clamp(line_mask, 0.0, 1.0));

	// Apply speckles
	color -= speckle * speckle_intensity;

	COLOR = vec4(color, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
