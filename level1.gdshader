shader_type canvas_item;

uniform sampler2D tex;
uniform float edge_falloff : hint_range(0.0, 1.0) = 0.11; // feather width
uniform float base_alpha : hint_range(0.0, 1.0) = 0.0; // base transparency multiplier

void fragment() {
    vec2 screen_center = vec2(0.5, 0.5);
    float dist = distance(SCREEN_UV, screen_center);
    float mask = smoothstep(0.5 - edge_falloff, 0.5, dist);
    
    vec4 tex_color = texture(tex, UV);
    tex_color.a *= mask * base_alpha;
    
    COLOR = tex_color;
}