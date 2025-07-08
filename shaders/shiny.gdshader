shader_type canvas_item;

uniform sampler2D texture_albedo;
uniform vec2 light_position = vec2(0.0, 0.0);
uniform float gloss_strength = 0.3;
uniform float roughness = 0.5;  // [0.0, 1.0]
uniform float shininess = 40.0; // controls highlight sharpness

void fragment() {
    vec2 world_uv = (UV - 0.5) * 128.0 + vec2(FRAGCOORD.x, FRAGCOORD.y);
    vec2 to_light = normalize(light_position - world_uv);
    vec2 normal = vec2(0.0, -1.0); // tiles facing upward

    float ndotl = max(dot(normal, to_light), 0.0);
    
    // Shinier tiles reflect more tightly
    float specular = pow(ndotl, mix(1.0, shininess, 1.0 - roughness));

    // Final gloss color
    float gloss = specular * (1.0 - roughness) * gloss_strength;

    vec4 tex_color = texture(texture_albedo, UV);
    vec3 final_color = mix(tex_color.rgb, vec3(1.0), gloss);

    COLOR = vec4(final_color, tex_color.a);
}