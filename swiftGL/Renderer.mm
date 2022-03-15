//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"


// small struct to hold object-specific information
struct RenderObject
{
    GLuint vao, ibo;    // VAO and index buffer object IDs

    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
};

// macro to hep with GL calls
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// uniform variables for shaders
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_LIGHT_SPECULAR_POSITION,
    UNIFORM_LIGHT_DIFFUSE_POSITION,
    UNIFORM_LIGHT_DIFFUSE_COMPONENT,
    UNIFORM_LIGHT_SHININESS,
    UNIFORM_LIGHT_SPECULAR_COMPONENT,
    UNIFORM_LIGHT_AMBIENT_COMPONENT,
    UNIFORM_USE_FOG,
    UNIFORM_USE_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    // OpenGL IDs
    GLuint programObject;
    GLuint crateTexture;

    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;

    // render objects
    RenderObject objects[49];

    // moving camera automatically
    float dist, distIncr;
}

@end

@implementation Renderer

@synthesize isRotating;
@synthesize rotAngle;
@synthesize useFog;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    // First cube (centre, textured)
    glGenVertexArrays(1, &objects[0].vao);
    glGenBuffers(1, &objects[0].ibo);

    // get cube data
    objects[0].numIndices = glesRenderer.GenCube(1.0f, &objects[0].vertices, &objects[0].normals, &objects[0].texCoords, &objects[0].indices);

    // set up VBOs (one per attribute)
    glBindVertexArray(objects[0].vao);
    GLuint vbo[3];
    glGenBuffers(3, vbo);

    // pass on position data
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[0].vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    // pass on normals
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[0].normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    // pass on texture coordinates
    glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
    glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), objects[0].texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[0].ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[0].indices[0]) * objects[0].numIndices, objects[0].indices, GL_STATIC_DRAW);


    // Second cube (to the side, not textured) - repeat above, minus the texture
    //glGenVertexArrays(1, &objects[1].vao);
    //glGenBuffers(1, &objects[1].ibo);

    //objects[1].numIndices = glesRenderer.GenCube(1.0f, &objects[1].vertices, &objects[1].normals, NULL, &objects[1].indices);

    //glBindVertexArray(objects[1].vao);

    //glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    //glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[1].vertices, GL_STATIC_DRAW);
    //glEnableVertexAttribArray(ATTRIB_POSITION);
    //glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    //glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
    //glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[1].normals, GL_STATIC_DRAW);
    //glEnableVertexAttribArray(ATTRIB_NORMAL);
    //glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[1].ibo);
    //glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[1].indices[0]) * objects[1].numIndices, objects[1].indices, GL_STATIC_DRAW);
    
    for (int i=1; i<sizeof(objects)/sizeof(objects[0]); i++) {
        glGenVertexArrays(1, &objects[i].vao);
        glGenBuffers(1, &objects[i].ibo);

        objects[i].numIndices = glesRenderer.GenCube(1.0f, &objects[i].vertices, &objects[i].normals, NULL, &objects[i].indices);

        glBindVertexArray(objects[i].vao);

        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[i].vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[i].normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_NORMAL);
        glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[i].ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[i].indices[0]) * objects[i].numIndices, objects[i].indices, GL_STATIC_DRAW);
        
    }
    
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders])
        return;

    // initialize rotation and camera distance
    rotAngle = 0.0f;
    isRotating = 1;
    dist = -5.0;
    distIncr = 0.00f;

    // texture and fog uniforms
    useFog = 0;
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);

    // set up lighting values
    specularComponent = GLKVector4Make(0.8f, 0.1f, 0.1f, 1.0f);
    specularLightPosition = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    shininess = 1000.0f;
    ambientComponent = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
    objects[0].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    objects[0].diffuseComponent = GLKVector4Make(0.1f, 0.8f, 0.1f, 1.0f);
    
    for (int i=1; i<sizeof(objects)/sizeof(objects[0]); i++) {
        objects[i].diffuseLightPosition = GLKVector4Make(-2.0f, 1.0f, 0.0f, 1.0f);
        objects[i].diffuseComponent = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);

    }

    //objects[1].diffuseLightPosition = GLKVector4Make(-2.0f, 1.0f, 0.0f, 1.0f);
    //objects[1].diffuseComponent = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    //objects[2].diffuseLightPosition = GLKVector4Make(-2.0f, 1.0f, 0.0f, 1.0f);
    //objects[2].diffuseComponent = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    
    // clear to black background
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    
    // update rotation and camera position
    if (isRotating)
    {
        rotAngle += 0.001f * elapsedTime;
        if (rotAngle >= 360.0f)
            rotAngle = 0.0f;
    }
    dist += distIncr;
    if ((dist >= -2.0f) || (dist <= -8.0f))
        distIncr = -distIncr;

    specularLightPosition = GLKVector4Make(0.0f, 0.0f, dist+2, 1.0f);   // make specular light move with camera
    
    // perspective projection matrix
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    
    // initialize MVP matrix for both objects to set the "camera"
    //objects[0].mvp = objects[1].mvp = objects[2].mvp =  GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, dist);
    for (int i=0; i<sizeof(objects)/sizeof(objects[0]); i++) {
        objects[i].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, dist);
        
    }

    // apply transformations to first (textured cube)
    objects[0].mvm = objects[0].mvp = GLKMatrix4Rotate(objects[0].mvp, rotAngle, 1.0, 0.0, 1.0 );
    objects[0].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[0].mvp), NULL);
    objects[0].mvp = GLKMatrix4Multiply(perspective, objects[0].mvp);

    // move second cube to the right (along positive-x axis), and apply projection matrix
    //objects[1].mvm = objects[1].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 1.5, 0.0, 0.0), objects[1].mvp);
    //objects[1].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[1].mvp), NULL);
    //objects[1].mvp = GLKMatrix4Multiply(perspective, objects[1].mvp);
    
    // move third cube to the left (along negative-x axis), and apply projection matrix
    //objects[2].mvm = objects[2].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, -1.5, 0.0, 0.0), objects[2].mvp);
    //objects[2].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[2].mvp), NULL);
    //objects[2].mvp = GLKMatrix4Multiply(perspective, objects[2].mvp);
    
    moveCubes(objects, 1, perspective, -1.5, 0);
    moveCubes(objects, 2, perspective, -1.5, -1);
    moveCubes(objects, 3, perspective, -2.5, 0);
    moveCubes(objects, 4, perspective, -2.5, -1);
    moveCubes(objects, 5, perspective, -2.5, -2);
    
    moveCubes(objects, 6, perspective, 1.5, 0);
    moveCubes(objects, 7, perspective, 1.5, -1);
    moveCubes(objects, 8, perspective, 1.5, 1);
    moveCubes(objects, 9, perspective, 2.5, 1);
    moveCubes(objects, 10, perspective, 2.5, 2);
    
    moveCubes(objects, 11, perspective, -1.5, 2);
    moveCubes(objects, 12, perspective, -1.5, 3);
    
    
    moveCubes(objects, 15, perspective, -4.5, 0);
    moveCubes(objects, 16, perspective, -4.5, 1);
    moveCubes(objects, 17, perspective, -4.5, 2);
    moveCubes(objects, 18, perspective, -3.5, 2);
    
    moveCubes(objects, 19, perspective, -4.5, 4);
    moveCubes(objects, 20, perspective, -4.5, 5);
    moveCubes(objects, 21, perspective, -3.5, 4);
    moveCubes(objects, 22, perspective, -3.5, 5);
    moveCubes(objects, 24, perspective, -2.5, 5);
    
    moveCubes(objects, 25, perspective, -0.5, 5);
    moveCubes(objects, 26, perspective, 0.5, 5);
    moveCubes(objects, 27, perspective, 1.5, 5);
    moveCubes(objects, 28, perspective, 2.5, 5);
    moveCubes(objects, 29, perspective, 2.5, 4);
    
    moveCubes(objects, 30, perspective, 4.5, 5);
    
    moveCubes(objects, 31, perspective, 4.5, 3);
    moveCubes(objects, 32, perspective, 4.5, 2);
    moveCubes(objects, 33, perspective, 4.5, 1);
    
    moveCubes(objects, 34, perspective, 4.5, -1);
    moveCubes(objects, 35, perspective, 4.5, -2);
    moveCubes(objects, 36, perspective, 3.5, -1);
    moveCubes(objects, 37, perspective, 3.5, -2);
    
    moveCubes(objects, 38, perspective, 4.5, -4);
    moveCubes(objects, 39, perspective, 3.5, -4);
    moveCubes(objects, 40, perspective, 2.5, -4);
    moveCubes(objects, 41, perspective, 1.5, -4);
    moveCubes(objects, 42, perspective, 1.5, -3);
    moveCubes(objects, 43, perspective, 0.5, -4);
    moveCubes(objects, 44, perspective, 0.5, -3);
    moveCubes(objects, 45, perspective, -0.5, -4);
    moveCubes(objects, 46, perspective, -0.5, -3);
    moveCubes(objects, 47, perspective, -1.5, -4);
    
    moveCubes(objects, 48, perspective, -3.5, -4);
    moveCubes(objects, 13, perspective, -4.5, -4);
    moveCubes(objects, 14, perspective, -4.5, -3);
    moveCubes(objects, 23, perspective, -4.5, -2);
}
void moveCubes(RenderObject objects[], int obj, GLKMatrix4 perspective, float x, float z) {
    objects[obj].mvm = objects[obj].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, x, 0.0, z), objects[obj].mvp);
    objects[obj].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[obj].mvp), NULL);
    objects[obj].mvp = GLKMatrix4Multiply(perspective, objects[obj].mvp);
    
}

- (void)draw:(CGRect)drawRect;
{
    // pass on global lighting, fog and texture values
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_POSITION], 1, specularLightPosition.v);
    glUniform1i(uniforms[UNIFORM_LIGHT_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT], 1, ambientComponent.v);
    glUniform1i(uniforms[UNIFORM_USE_FOG], useFog);

    // set up GL for drawing
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    // for first cube, use texture and object-specific diffuse light, then pass on the object-specific matrices and VAO/IBO
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[0].diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[0].diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[0].mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[0].mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[0].normalMatrix.m);
    glBindVertexArray(objects[0].vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[0].ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)objects[0].numIndices, GL_UNSIGNED_INT, 0);
    
    // for second cube, turn off texture and use object-specific diffuse light, then pass on the object-specific matrices and VAO/IBO
    //glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 0);
    //glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[1].diffuseLightPosition.v);
    //glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[1].diffuseComponent.v);
    //glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[1].mvp.m);
    //glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[1].mvm.m);
    //glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[1].normalMatrix.m);
    //glBindVertexArray(objects[1].vao);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[1].ibo);
    //glDrawElements(GL_TRIANGLES, (GLsizei)objects[1].numIndices, GL_UNSIGNED_INT, 0);
    
    // for third cube, turn off texture and use object-specific diffuse light, then pass on the object-specific matrices and VAO/IBO
    //glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 0);
    //glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[2].diffuseLightPosition.v);
    //glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[2].diffuseComponent.v);
    //glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[2].mvp.m);
    //glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[2].mvm.m);
    //glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[2].normalMatrix.m);
    //glBindVertexArray(objects[2].vao);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[2].ibo);
    //glDrawElements(GL_TRIANGLES, (GLsizei)objects[2].numIndices, GL_UNSIGNED_INT, 0);

    for (int i=1; i<sizeof(objects)/sizeof(objects[0]); i++) {
        glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 0);
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[i].diffuseLightPosition.v);
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[i].diffuseComponent.v);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[i].mvp.m);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[i].mvm.m);
        glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[i].normalMatrix.m);
        glBindVertexArray(objects[i].vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[i].ibo);
        glDrawElements(GL_TRIANGLES, (GLsizei)objects[i].numIndices, GL_UNSIGNED_INT, 0);    }
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(programObject, "modelViewMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    uniforms[UNIFORM_LIGHT_SPECULAR_POSITION] = glGetUniformLocation(programObject, "specularLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION] = glGetUniformLocation(programObject, "diffuseLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT] = glGetUniformLocation(programObject, "diffuseComponent");
    uniforms[UNIFORM_LIGHT_SHININESS] = glGetUniformLocation(programObject, "shininess");
    uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT] = glGetUniformLocation(programObject, "specularComponent");
    uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT] = glGetUniformLocation(programObject, "ambientComponent");
    uniforms[UNIFORM_USE_FOG] = glGetUniformLocation(programObject, "useFog");
    uniforms[UNIFORM_USE_TEXTURE] = glGetUniformLocation(programObject, "useTexture");

    return true;
}


// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

@end

