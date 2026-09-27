shader_type spatial;
render_mode unshaded, fog_disabled;

// Uniforms disponíveis no renderizador Compatibility
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform float line_dark : hint_range(0.0, 2.0) = 0.5;

float get_linear_depth(vec2 uv, mat4 inv_proj_mat) {
    float depth = texture(depth_texture, uv).r;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
    vec4 view = inv_proj_mat * vec4(ndc, 1.0);
    view.xyz /= view.w;
    return -view.z;
}

void vertex() {
    POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

void fragment() {
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE;

    vec2 uvs[4];
    uvs[0] = SCREEN_UV + vec2(-pixel_size.x, 0.0);
    uvs[1] = SCREEN_UV + vec2(pixel_size.x, 0.0);
    uvs[2] = SCREEN_UV + vec2(0.0, pixel_size.y);
    uvs[3] = SCREEN_UV + vec2(0.0, -pixel_size.y);

    // Detecção de bordas baseada apenas em Depth
    float depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float depth_diff = 0.0;

    for (int i = 0; i < 4; i++) {
        float neighbor_depth = get_linear_depth(uvs[i], INV_PROJECTION_MATRIX);
        depth_diff += clamp(neighbor_depth - depth, 0.0, 1.0);
    }

    depth_diff = smoothstep(0.05, 0.3, depth_diff);

    vec3 albedo = texture(screen_texture, SCREEN_UV).rgb;
    albedo -= depth_diff * line_dark;

    ALBEDO = albedo;
}