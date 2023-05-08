#include <metal_stdlib>
using namespace metal;

#include "definitions.h"

struct VertexIn {
    float4 position [[attribute(0)]];
    float3 color [[attribute(1)]];
    float3 normal [[attribute(2)]];
    float2 uv [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

vertex VertexOut vertexShader(
    const VertexIn vertex_in [[stage_in]],
    const device ShaderUniforms& uniforms[[buffer(1)]]
) {

    VertexOut output;
    output.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertex_in.position;

    output.normal = vertex_in.normal;

    switch (uniforms.attributeSelector) {
    case VertexAttributePosition:
        output.color = float4(vertex_in.position);
        break;
    case VertexAttributeColor:
        output.color = float4(vertex_in.color, 1.0);
        break;
    case VertexAttributeNormal:
        output.color = float4(vertex_in.normal, 1.0);
        break;
    case VertexAttributeTexCoord:
        output.color = float4(vertex_in.uv, 0.0, 1.0);
        break;
    default:
        output.color = float4(1.0);
    }
    
    return output;
}

fragment float4 fragmentShader(VertexOut input [[stage_in]]) {
    float3 lightPosition = float3(0.0, -2.0, 0.0);
    float3 directionToLight = normalize(-lightPosition);
    
    float3 light;
    
    float ambientItensity = 0.5;
    float diffuseIntensity = max(dot(input.normal, directionToLight), 0.0);
    
    light = diffuseIntensity * float3(0.0, 0.0, 1.0) + ambientItensity * float3(1.0, 0.0, 0.0);

    return float4(light, 1.0);
}


// infinite xz grid shader based on:
// https://asliceofrendering.com/scene%20helper/2020/01/05/InfiniteGrid/

struct GridPassThrough {
    float4 position [[position]];
    float4 color;
    float3 nearPoint;
    float3 farPoint;
};

float3 unprojectPoint(float x, float y, float z, float4x4 inverseView, float4x4 inverseProjection) {
    float4 unprj = inverseView * inverseProjection * float4(x, y, z, 1.0);
    return unprj.xyz / unprj.w;
}

vertex GridPassThrough gridVertexShader(
    const device Vertex *vertices[[buffer(0)]],
    unsigned int id[[vertex_id]],
    const device ShaderUniforms& uniforms[[buffer(1)]]
) {
    int3 gridPlane[] = {
        int3(-1, -1, 0),
        int3( 1,  1, 0),
        int3(-1,  1, 0),
        int3( 1,  1, 0),
        int3(-1, -1, 0),
        int3( 1, -1, 0),
    };
    
    GridPassThrough output;
    
    float3 p = float3(gridPlane[id]);
    
    output.position = float4(p, 1.0);
    output.color = uniforms.projectionMatrix * uniforms.modelMatrix * float4(1.0, 0.0, 0.0, 1.0);
    output.nearPoint = unprojectPoint(p.x, p.y, 0.0, uniforms.inverseViewMatrix, uniforms.inverseProjectionMatrix);
    output.farPoint = unprojectPoint(p.x, p.y, 1.0, uniforms.inverseViewMatrix, uniforms.inverseProjectionMatrix);
    return output;
}

float4 grid(float3 position, float scale) {
    float2 coords = position.xz * scale;
    float2 derivative = fwidth(coords);
    float2 grid = abs(fract(coords - 0.5) - 0.5) / derivative;
    float line = min(grid.x, grid.y);
    float minz = min(derivative.y, 1.0);
    float minx = min(derivative.x, 1.0);
    float3 color = float3(0.2, 0.2, 0.2);
    float alpha = 1.0 - min(line, 1.0);
    
    if (position.x > -(1.0 / scale) * minx && position.x < (1.0 / scale) * minx) {
        color.z = 1.0;
    }
    
    if (position.z > -(1.0 / scale) * minz && position.z < (1.0 / scale) * minz) {
        color.x =  1.0;
    }

    return float4(color * alpha, alpha);
}

float computeDepth(float3 position, float4x4 view, float4x4 projection) {
    float4 clipSpacePosition = projection * view * float4(position, 1.0);
    return clipSpacePosition.z / clipSpacePosition.w;
}

float computeLinearDepth(float3 position, float nearClip, float farClip, float4x4 view, float4x4 projection) {
    float4 clipSpacePosition = projection * view * float4(position, 1.0);
    float clipSpaceDepth = (clipSpacePosition.z / clipSpacePosition.w) * 2.0 - 1.0;
    float linearDepth = (2.0 * nearClip * farClip) / (farClip + nearClip - clipSpaceDepth * (farClip - nearClip));
    return linearDepth / farClip;
}

struct GridFragmentOut {
    float4 color[[color(0)]];
    float depth [[depth(any)]];
};

fragment GridFragmentOut gridFragmentShader(
    GridPassThrough input [[stage_in]],
    const device ShaderUniforms& uniforms[[buffer(1)]]
) {
    float t = -input.nearPoint.y / (input.farPoint.y - input.nearPoint.y);
    float3 position = input.nearPoint + t * (input.farPoint - input.nearPoint);
    float depth = computeDepth(position, uniforms.viewMatrix, uniforms.projectionMatrix);
    float linearDepth = computeLinearDepth(position, uniforms.nearClip, uniforms.farClip, uniforms.viewMatrix, uniforms.projectionMatrix);
    float fade = 1.0 - linearDepth;
    
    float4 color = grid(position, 1) * float(t > 0) * fade;
    
    GridFragmentOut out;
    out.color = color;
    out.depth = depth;
    return out;
}
