shader_type canvas_item;

uniform float gloss_strength = 0.25; // How strong the shine is
uniform float gloss_width = 0.15;    // Width of the shine band
uniform float time_speed = 0.5;      // Speed of the animation

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);

    // Moving diagonal highlight
    float wave = uv.x + uv.y + sin(TIME * time_speed);
    float gloss = smoothstep(0.5 - gloss_width, 0.5, wave) *
                  smoothstep(0.5 + gloss_width, 0.5, wave);

    // Blend white highlight into the original texture
    vec3 highlight = mix(tex_color.rgb, vec3(1.0), gloss * gloss_strength);

    COLOR = vec4(highlight, tex_color.a);
}