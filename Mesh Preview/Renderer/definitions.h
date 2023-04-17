#ifndef defines_h
#define defines_h

#include <simd/simd.h>

struct Vertex {
    vector_float3 position;
    vector_float3 color;
    vector_float3 normal;
};

struct VertexShaderUniforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 inverseViewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 inverseProjectionMatrix;
    float nearClip;
    float farClip;
};

#endif /* defines_h */
