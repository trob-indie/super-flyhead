shader_type canvas_item;

uniform float time_scale = 0.25;
uniform float swirl_amount = 0.5;

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_scale;

    // Swirl/pulse UVs for trippy effect
    float swirl = swirl_amount * sin(uv.y * 8.0 + t * 1.3) * cos(uv.x * 8.0 - t * 1.1);
    uv += swirl * 0.06 * vec2(sin(t + uv.y * 3.1), cos(t + uv.x * 2.7));
    float pulse = 0.1 + 0.07 * sin(t * 1.5 + uv.x * 4.0 + uv.y * 6.0);
    uv = 0.5 + (uv - 0.5) * (1.0 + pulse);

    // Sample grayscale value
    float value = texture(TEXTURE, fract(uv)).r;
    value = pow(value, 5.0); // High exponent for extreme contrast

    // Palette colors
    vec3 black = vec3(0.0, 0.0, 0.0);
    vec3 dark_red = vec3(0.4, 0.05, 0.05);
    vec3 dark_purple = vec3(0.15, 0.04, 0.20);

    // Subtle oscillating palette shift between dark_red and dark_purple
    float subtle_shift = 0.2 * sin(t * 2.1 + uv.x * 10.0 + uv.y * 15.0);
    float blend = 0.5 + 0.5 * subtle_shift; // oscillates between 0.3 and 0.7
    vec3 palette = mix(dark_red, dark_purple, blend);

    // Gradient from black to palette based on grayscale value
    vec3 color = mix(black, palette, value);

    COLOR = vec4(color, 1.0);
}