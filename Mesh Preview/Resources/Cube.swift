//
//  Cube.swift
//  CSCI598D_P02_ECK
//
//  Created by Dylan Eck on 4/11/23.
//

import Foundation

struct Cube {
    let vertices: [Vertex] = [
        // Front face
        Vertex(position: vector_float3(1, 0, 0), color: vector_float3(1, 0, 0), normal: vector_float3(0, 0, -1)),
        Vertex(position: vector_float3(0, 0, 0), color: vector_float3(0, 0, 0), normal: vector_float3(0, 0, -1)),
        Vertex(position: vector_float3(1, 1, 0), color: vector_float3(1, 1, 0), normal: vector_float3(0, 0, -1)),
        Vertex(position: vector_float3(1, 1, 0), color: vector_float3(1, 1, 0), normal: vector_float3(0, 0, -1)),
        Vertex(position: vector_float3(0, 0, 0), color: vector_float3(0, 0, 0), normal: vector_float3(0, 0, -1)),
        Vertex(position: vector_float3(0, 1, 0), color: vector_float3(0, 1, 0), normal: vector_float3(0, 0, -1)),

        // Right face
        Vertex(position: vector_float3(1, 0, 1), color: vector_float3(1, 0, 1), normal: vector_float3(1, 0, 0)),
        Vertex(position: vector_float3(1, 0, 0), color: vector_float3(1, 0, 0), normal: vector_float3(1, 0, 0)),
        Vertex(position: vector_float3(1, 1, 1), color: vector_float3(1, 1, 1), normal: vector_float3(1, 0, 0)),
        Vertex(position: vector_float3(1, 1, 1), color: vector_float3(1, 1, 1), normal: vector_float3(1, 0, 0)),
        Vertex(position: vector_float3(1, 0, 0), color: vector_float3(1, 0, 0), normal: vector_float3(1, 0, 0)),
        Vertex(position: vector_float3(1, 1, 0), color: vector_float3(1, 1, 0), normal: vector_float3(1, 0, 0)),

        // Left face
        Vertex(position: vector_float3(0, 0, 0), color: vector_float3(0, 0, 0), normal: vector_float3(-1, 0, 0)),
        Vertex(position: vector_float3(0, 0, 1), color: vector_float3(0, 0, 1), normal: vector_float3(-1, 0, 0)),
        Vertex(position: vector_float3(0, 1, 0), color: vector_float3(0, 1, 0), normal: vector_float3(-1, 0, 0)),
        Vertex(position: vector_float3(0, 1, 0), color: vector_float3(0, 1, 0), normal: vector_float3(-1, 0, 0)),
        Vertex(position: vector_float3(0, 0, 1), color: vector_float3(0, 0, 1), normal: vector_float3(-1, 0, 0)),
        Vertex(position: vector_float3(0, 1, 1), color: vector_float3(0, 1, 1), normal: vector_float3(-1, 0, 0)),

        // Top face
        Vertex(position: vector_float3(1, 1, 0), color: vector_float3(1, 1, 0), normal: vector_float3(0, 1, 0)),
        Vertex(position: vector_float3(0, 1, 0), color: vector_float3(0, 1, 0), normal: vector_float3(0, 1, 0)),
        Vertex(position: vector_float3(1, 1, 1), color: vector_float3(1, 1, 1), normal: vector_float3(0, 1, 0)),
        Vertex(position: vector_float3(1, 1, 1), color: vector_float3(1, 1, 1), normal: vector_float3(0, 1, 0)),
        Vertex(position: vector_float3(0, 1, 0), color: vector_float3(0, 1, 0), normal: vector_float3(0, 1, 0)),
        Vertex(position: vector_float3(0, 1, 1), color: vector_float3(0, 1, 1), normal: vector_float3(0, 1, 0)),

        // Bottom face
        Vertex(position: vector_float3(0, 0, 0), color: vector_float3(0, 0, 0), normal: vector_float3(0, -1, 0)),
        Vertex(position: vector_float3(0, 0, 1), color: vector_float3(0, 0, 1), normal: vector_float3(0, -1, 0)),
        Vertex(position: vector_float3(1, 0, 1), color: vector_float3(1, 0, 1), normal: vector_float3(0, -1, 0)),
        Vertex(position: vector_float3(0, 0, 0), color: vector_float3(0, 0, 0), normal: vector_float3(0, -1, 0)),
        Vertex(position: vector_float3(1, 0, 1), color: vector_float3(1, 0, 1), normal: vector_float3(0, -1, 0)),
        Vertex(position: vector_float3(1, 0, 0), color: vector_float3(1, 0, 0), normal: vector_float3(0, -1, 0)),
    ]
}
