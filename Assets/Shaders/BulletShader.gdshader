shader_type canvas_item;

uniform vec4 glow_color;         // e.g. (1.0, 0.5, 0.0, 1.0)
uniform float glow_strength;     // e.g. 1.0
uniform float highlight_radius;  // e.g. 0.3
uniform float softness;
uniform float pulse_speed;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    float highlight = smoothstep(highlight_radius + softness, highlight_radius, dist);

    float animated_strength = glow_strength * (0.5 + 0.5 * sin(TIME * pulse_speed));

    vec4 tex_color = texture(TEXTURE, UV);
    vec3 color = tex_color.rgb + glow_color.rgb * highlight * animated_strength;

}