#version 300 es

// vertex attributes
layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texCoordIn;

// output of vertex shader (these will be interpolated for each call to the fragment shader)
out vec3 eyeNormal;
out vec4 eyePos;
out vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

void main()
{
    // Calculate normal vector in eye coordinates
    eyeNormal = (normalMatrix * normal);
    
    // Calculate vertex position in view coordinates
    eyePos = modelViewMatrix * position;
    
    // Pass through texture coordinate
    texCoordOut = texCoordIn;

    // Set gl_Position with transformed vertex position
    gl_Position = modelViewProjectionMatrix * position;
}
