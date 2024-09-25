#version 300 es
precision highp float;
precision highp int;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform int u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

#define NUM_OCTAVES 5

// fbm code same from fire frag shader, modified from the book of shaders
float random(vec2 x) {
    return fract(sin(dot(x.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0)); 

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rotation = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));

    for (int i = 0; i < NUM_OCTAVES; ++i) {
        value += amplitude * noise(x);
        x = rotation * x * 2.0 + shift;
        amplitude *= 0.5;
    }

    return value;
}
 
void main() {
    float time = float(u_Time) * 0.01;
    vec2 st = gl_FragCoord.xy / vec2(800.0, 600.0) * 2.0;
    vec2 staticSt = gl_FragCoord.xy / vec2(800.0, 600.0) * 2.0;
    st += vec2(time * 0.1, time * 0.05);

    vec3 sky = vec3(0.035,0.125,0.251);
    vec3 cloud = vec3(0.16, 0.76, 1);

    vec3 color = mix(sky, cloud, smoothstep(0.5, 1.0, fbm(st)));

    out_Col = vec4(color, 1.0);
}
