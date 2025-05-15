shader_type canvas_item;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0, 0.5, 0.5); // default: light pink

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = mix(tex_color, vec4(flash_color, tex_color.a), flash_strength);
}
