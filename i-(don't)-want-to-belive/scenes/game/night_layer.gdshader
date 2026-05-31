shader_type canvas_item;

uniform vec2 player_screen_pos;
uniform float inner_radius = 0.02;
uniform float outer_radius = 0.1;
uniform float min_alpha = 0.50; 

void fragment() {
    vec4 my_color = COLOR;
    float dist = distance(SCREEN_UV, player_screen_pos);
    float mask = smoothstep(inner_radius, outer_radius, dist);
    float final_alpha = mix(min_alpha, 1.0, mask);
    
    my_color.a *= final_alpha;
    COLOR = my_color;
}
