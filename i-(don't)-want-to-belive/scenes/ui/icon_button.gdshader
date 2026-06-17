shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 5.0; // Ustaw na tyle, ile ma czcionka (np. 5.0)

void fragment() {
    vec4 raw_texture = texture(TEXTURE, UV);
    vec4 modulated_color = raw_texture * COLOR;
    
    if (outline_width <= 0.0) {
        COLOR = modulated_color;
    } else {
        vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
        float max_alpha = 0.0;
        int samples = 16; 
        
        for (int i = 0; i < samples; i++) {
            float angle = float(i) * (2.0 * 3.1415926535) / float(samples);
            vec2 direction = vec2(cos(angle), sin(angle));
            vec2 sample_uv = UV + direction * size;
            
            if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
                max_alpha = max(max_alpha, texture(TEXTURE, sample_uv).a);
            }
        }
        
        float edge_softness = TEXTURE_PIXEL_SIZE.x * 1.5;
        float outline_factor = smoothstep(0.0, edge_softness, max_alpha);
        
        if (raw_texture.a == 0.0) {
            COLOR = vec4(outline_color.rgb, outline_color.a * outline_factor);
        } else {
            COLOR = mix(vec4(outline_color.rgb, outline_color.a * outline_factor), modulated_color, raw_texture.a);
        }
    }
}
