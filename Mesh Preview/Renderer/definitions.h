#ifndef definitions_h
#define definitions_h

#import <simd/simd.h>

typedef enum {
    VertexAttributeNone = 0,
    VertexAttributePosition = 1,
    VertexAttributeColor = 2,
    VertexAttributeNormal = 3,
    VertexAttributeTexCoord = 4
} VertexAttribute;

struct Vertex {
    vector_float3 position;
    vector_float3 color;
    vector_float3 normal;
};

struct ShaderUniforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 inverseViewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 inverseProjectionMatrix;
    float nearClip;
    float farClip;
    uint attributeSelector;
};

#endif
