shader_type particles;

uniform vec3 wind_direction = vec3(1.0, 0.1, 0.0);
uniform float wind_speed = 12.0;
uniform float turbulence_strength = 2.5;

// Função auxiliar para gerar ruído/seemente
float rand(inout uint seed) {
    seed = (seed ^ 61u) ^ (seed >> 16u);
    seed *= 9u;
    seed = seed ^ (seed >> 4u);
    seed *= 0x27d4eb2du;
    seed = seed ^ (seed >> 15u);
    return float(seed) / 4294967295.0;
}

// Executado no nascimento/reinício da partícula
void start() {
    uint seed = INDEX + uint(TIME * 1000.0);
    
    // Posição inicial com emissão em caixa (Box Emission)
    vec3 spawn_offset = vec3(
        (rand(seed) - 0.5) * 10.0,
        (rand(seed) - 0.5) * 5.0,
        (rand(seed) - 0.5) * 10.0
    );
    TRANSFORM[3].xyz = spawn_offset;
    
    // Direção inicial com variação aleatória
    vec3 dir = normalize(wind_direction + vec3(
        (rand(seed) - 0.5) * 0.2,
        (rand(seed) - 0.5) * 0.2,
        (rand(seed) - 0.5) * 0.2
    ));
    
    VELOCITY = dir * wind_speed;
    COLOR.a = 1.0;
    
    // Inicializa o contador de tempo de vida no canal CUSTOM.x
    CUSTOM.x = 0.0; 
}

// Executado a cada frame durante a vida da partícula
void process() {
    // Atualiza o ciclo de vida relativo (de 0.0 a 1.0)
    CUSTOM.x += DELTA / LIFETIME;
    float age_ratio = clamp(CUSTOM.x, 0.0, 1.0);
    
    // Aplica uma onda senoidal no eixo Y/Z para criar o movimento do vento
    float time_offset = TIME * 3.0 + TRANSFORM[3].x;
    vec3 wave = vec3(
        0.0,
        sin(time_offset) * turbulence_strength,
        cos(time_offset * 0.8) * turbulence_strength
    );
    
    VELOCITY += wave * DELTA;
    
    // Alinha a rotação da partícula com a direção em que voa
    if (length(VELOCITY) > 0.1) {
        vec3 forward = normalize(VELOCITY);
        vec3 up = vec3(0.0, 1.0, 0.0);
        vec3 right = normalize(cross(up, forward));
        up = cross(forward, right);
        
        TRANSFORM[0].xyz = right;
        TRANSFORM[1].xyz = up;
        TRANSFORM[2].xyz = forward;
    }
    
    // Fade out gradual no final da vida da partícula
    COLOR.a = 1.0 - smoothstep(0.7, 1.0, age_ratio);
}