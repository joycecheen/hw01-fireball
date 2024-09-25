#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec3 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

uniform int u_Time;
uniform float u_Speed;

// Generating FBM 3D code from CIS 4600
float noise3D(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 191.999))) * 43758.5453);
}

float interpNoise3D(vec3 p) {
    int intX = int(floor(p.x));
    float fractX = fract(p.x);
    int intY = int(floor(p.y));
    float fractY = fract(p.y);
    int intZ = int(floor(p.z));
    float fractZ = fract(p.z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float j1 = mix(i1, i2, fractY);
    float j2 = mix(i3, i4, fractY);

    return mix(j1, j2, fractZ);
}

float fbm(vec3 x, float f) {
    float total = 0.0;
    float persistence = 0.5;
    int octaves = 8;
    float freq = f;
    float amp = 0.5;

    for (int i = 0; i < octaves; i++) {
        total += interpNoise3D(x * freq) * amp;
        freq *= 2.0;
        amp *= persistence;
    }

    return smoothstep(-1.0, 1.0, total);
}

// modified from the book of shaders fractal brownian motion
float superpositionSin(float value, float amplitude, float frequency, float time) {
    float t = -time * (u_Speed * 0.05);
    float result = 0.0;
    result += sin(value * frequency * 1.5 + t) * 0.8;
    result += sin(value * frequency * 2.3 + t * 1.3) * 0.6;
    result += sin(value * frequency * 3.7 + t * 1.7) * 0.8;
    result += sin(value * frequency * 4.5 + t * 2.1) * 0.2;
    return amplitude * result * 0.1;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float time = float(u_Time);

    // manually distort sphere into tear drop
    vec3 pos = vec3(modelposition);
    pos.xyz *= vec3(1.5, 1.1, 1.5);
    float heightFactor = 1.0 + 0.5 * smoothstep(0.0, 1.0, pos.y); 
    pos.y *= heightFactor;
    if (pos.y > 0.0) {
        pos *= vec3(1.0, 1.0 + 0.2 * pos.y, 1.0);
    }
    
    // low freq, high amp sin displacement of sphere shape
    float frequency = 2.5;
    float amplitude = 0.8; 
    pos.xz += superpositionSin(pos.y, amplitude, frequency, time);
    pos.xz -= 0.25 * pos.y;

    // high freq, low amp fbm texture distortion
    float fbmFrequency = 23.0;
    float fbmAmplitude = 0.12;
    float finerFBM = fbm(pos * fbmFrequency + vec3(time * 0.5), 0.5); 
    pos.xyz += fbmAmplitude * finerFBM;
    
    modelposition = vec4(pos, 1.0);

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
    fs_Pos = pos;
}
