shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// =========================
// CORES
// =========================
// O parâmetro ": source_color" permite colocar o Hexadecimal direto no Inspector!
// O vec4 é (Vermelho, Verde, Azul, Transparência).
// 0.19, 0.28, 0.26 é a conversão de #314743 para a escala 0 a 1 do shader.

uniform vec4 color_shallow : source_color = vec4(0.19, 0.28, 0.26, 0.85); // Seu #314743
uniform vec4 color_deep : source_color    = vec4(0.05, 0.15, 0.20, 0.95); // Azul/Verde mais escuro
uniform vec4 color_edge : source_color    = vec4(0.35, 0.50, 0.55, 1.0);  // Cor do reflexo/horizonte

// =========================
// ONDAS
// =========================
uniform float wave_height : hint_range(0.0, 1.0) = 0.12;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.6;
uniform float wave_scale : hint_range(0.1, 10.0) = 2.5;

// =========================
// NORMAL / DISTORÇÃO
// =========================
uniform sampler2D normal_map : hint_normal;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.5;
uniform float normal_speed = 0.15;
uniform float normal_scale = 3.0;

// =========================
// REFLEXO
// =========================
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.15;
uniform float roughness_amount : hint_range(0.0, 1.0) = 0.15;
uniform float fresnel_strength : hint_range(0.0, 5.0) = 2.0;

// =========================
// VARIÁVEIS
// =========================
varying vec3 world_position;
varying float wave_blend; // Usado para misturar as cores com base na altura

void vertex() {
	// Posição no mundo
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Tempo da animação
	float t = TIME * wave_speed;

	// Coordenadas das ondas
	float wave1 = sin(VERTEX.x * wave_scale + t);
	float wave2 = cos(VERTEX.z * wave_scale * 1.3 + t * 1.2);
	float wave3 = sin((VERTEX.x + VERTEX.z) * wave_scale * 0.7 + t * 0.8);

	// Combina várias ondas (resultado vai de -1.0 a +1.0)
	float waves = (wave1 + wave2 + wave3) / 3.0;

	// Normaliza o valor da onda para ir de 0.0 a 1.0 (perfeito para misturar cores)
	wave_blend = (waves + 1.0) * 0.5;

	// Move os vértices verticalmente
	VERTEX.y += waves * wave_height;
}

void fragment() {
	// =========================
	// NORMAL MAP ANIMADO
	// =========================
	vec2 uv1 = world_position.xz * normal_scale;
	vec2 uv2 = world_position.xz * normal_scale * 1.7;

	uv1 += vec2(TIME * normal_speed, TIME * normal_speed * 0.5);
	uv2 += vec2(-TIME * normal_speed * 0.7, TIME * normal_speed);

	vec3 normal1 = texture(normal_map, uv1).rgb;
	vec3 normal2 = texture(normal_map, uv2).rgb;

	normal1 = normal1 * 2.0 - 1.0;
	normal2 = normal2 * 2.0 - 1.0;

	vec3 water_normal = normalize(normal1 + normal2);

	NORMAL_MAP = water_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;

	// =========================
	// FRESNEL (ÂNGULO DE VISÃO)
	// =========================
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
	float fresnel = 1.0 - max(dot(NORMAL, view_dir), 0.0);
	fresnel = pow(fresnel, fresnel_strength);

	// =========================
	// MISTURA DAS CORES
	// =========================
	
	// 1. Mistura a cor funda e a rasa baseado na altura da onda
	vec3 base_color = mix(color_deep.rgb, color_shallow.rgb, wave_blend);
	float base_alpha = mix(color_deep.a, color_shallow.a, wave_blend);

	// 2. Mistura o resultado acima com a cor da borda baseado no ângulo (Fresnel)
	vec3 final_color = mix(base_color, color_edge.rgb, fresnel);
	float final_alpha = mix(base_alpha, color_edge.a, fresnel);

	ALBEDO = final_color;
	ALPHA = final_alpha;

	// =========================
	// MATERIAL
	// =========================
	METALLIC = metallic_amount;
	ROUGHNESS = roughness_amount;
	EMISSION = final_color * 0.02; // Brilho bem suave
}