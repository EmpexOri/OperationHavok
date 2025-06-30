shader_type canvas_item;

uniform float flash_speed = 10.0;
uniform float flash_intensity = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float flash = abs(sin(TIME * flash_speed)) * flash_intensity;
    COLOR = tex_color * (1.0 + flash);
}
