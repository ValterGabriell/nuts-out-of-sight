shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never;

uniform vec4 cor_som : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float progresso : hint_range(0.0, 1.0) = 0.0; 
uniform float espessura : hint_range(0.01, 0.2) = 0.05;
uniform float raio_maximo_anel : hint_range(0.05, 0.5) = 0.45;

void fragment() {
    // Normaliza UV para o centro (de -0.5 a 0.5)
    vec2 uv_centrado = UV - vec2(0.5);
    float dist = length(uv_centrado);

    
    float raio_atual = progresso * raio_maximo_anel;

    
    float anel = smoothstep(raio_atual - espessura, raio_atual, dist) - 
                 smoothstep(raio_atual, raio_atual + espessura, dist);

    
    float alpha = anel * (1.0 - progresso);

    ALBEDO = cor_som.rgb;
    ALPHA = clamp(alpha, 0.0, 1.0);
}