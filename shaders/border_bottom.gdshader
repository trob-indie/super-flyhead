shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // black
uniform int line_height = 2;

void fragment() {
    float tex_height = float(textureSize(TEXTURE, 0).y);
    float threshold_uv = float(line_height) / tex_height;

    vec4 tex_color = texture(TEXTURE, UV);

    if (UV.y >= 1.0 - threshold_uv) {
        COLOR = line_color * tex_color.a; // preserve transparency
    } else {
        COLOR = tex_color;
    }
}