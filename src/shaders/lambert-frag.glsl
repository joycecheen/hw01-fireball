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

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_EyeAngle;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec3 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.05;

    float lightIntensity = 2.5 * diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    vec4 baseColor = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

    if (normalize(fs_Nor.xyz).z <= 0.0) {
        out_Col = baseColor;
        return;
    }

    // draw eyes
    vec2 fragPos = normalize(fs_Pos).xy;
    float s = sin(u_EyeAngle), c = cos(u_EyeAngle);
    vec2 lEye = vec2(-0.4, 0.1);
    vec2 rEye = vec2(0.4, 0.1);

    vec2 lOffset = fragPos - lEye;
    vec2 lRot = vec2((c * lOffset.x) - (s * lOffset.y), (s * lOffset.x) + (c * lOffset.y));
    if (length(lRot) < 0.4 && lRot.y < 0.0) {
        out_Col = vec4(1.0);
        return;
    }
    vec2 rOffset = fragPos - rEye;
    vec2 rRot = vec2((c * rOffset.x) + (s * rOffset.y), (-s * rOffset.x) + (c * rOffset.y));
    if (length(rRot) < 0.4 && rRot.y < 0.0) {
        out_Col = vec4(1.0);
    } else {
        out_Col = baseColor;
    }
}
