#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;
precision highp int;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

uniform int u_Time;

#define NUM_OCTAVES 5

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

// customized from the book of shaders fractal brownian motion
float superpositionSin(float value, float amplitude, float baseFrequency, float time) {
    float t = -time * 0.2;
    float result = 0.0;
    result += sin(value * baseFrequency * 1.2 + t) * 1.0;
    result += sin(value * baseFrequency * 1.7 + t * 1.2) * 0.8;
    result += sin(value * baseFrequency * 2.1 + t * 0.5) * 1.5;
    result += sin(value * baseFrequency * 2.7 + t * 1.8) * 0.6;
    return amplitude * result * 0.1;
}

void main() {
    float time = float(u_Time) * 0.01;
    vec2 st = gl_FragCoord.xy / vec2(800.0, 600.0) * 3.0; // Adjust this based on your viewport size
    vec3 color = vec3(0.0);

    float frequency = 2.5;
    float amplitude = 0.8;
    st.x += superpositionSin(st.y, amplitude, frequency, time);
    st.y -= time * 1.7;
    
    vec2 q = vec2(0.0);
    q.x = fbm(st + 0.0 * time);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.0);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.15 * time);
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.126 * time);

    float f = fbm(st + r);

    color = mix(vec3(0.36,0.0,0.64),
                vec3(0.36,0.0,0.64),
                clamp((f*f)*4.0,0.0,1.0));

    color = mix(color,
                vec3(1.0,0.01,0.26),
                clamp(length(q),0.0,1.0));

    color = mix(color,
                vec3(u_Color),
                clamp(length(r.x),0.0,1.0));

    float screenY = gl_FragCoord.y / 650.0;
    float whiteBlendFactor = smoothstep(0.75, 1.0, screenY);
    color = mix(color, vec3(0.97, 0.65, 1.0), whiteBlendFactor);

    out_Col = vec4((f * f * f + 0.6 * f * f + 0.5 * f) * color, 0.3);
}