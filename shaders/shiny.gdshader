shader_type canvas_item;

uniform sampler2D texture_albedo;
uniform float gloss_strength = 0.25;
uniform float gloss_width = 0.15;
uniform float time_speed = 0.5;

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(texture_albedo, uv);

    float wave = uv.x + uv.y + sin(TIME * time_speed);
    float gloss = smoothstep(0.5 - gloss_width, 0.5, wave) *
                  smoothstep(0.5 + gloss_width, 0.5, wave);

    vec3 highlight = mix(tex_color.rgb, vec3(1.0), gloss * gloss_strength);
    COLOR = vec4(highlight, tex_color.a);
}