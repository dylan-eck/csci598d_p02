//
//  Mat4.swift
//  CSCI598D_P02_ECK
//
//  Created by Dylan Eck on 4/13/23.
//

import Foundation

typealias Vec2 = simd_float2
extension Vec2 {
    var formattedString: String {
        String(format: "(% .4f, % .4f)", self.x, self.y)
    }
}

typealias Vec3 = simd_float3
extension Vec3 {
    init(_ value: Float32) {
        self.init(repeating: value)
    }
}


typealias Vec4 = simd_float4

typealias Mat4 = simd_float4x4
extension Mat4 {
    static func rotateX(_ matrix: Mat4, _ angle: Float32) -> Mat4 {
        let rotation = Mat4(rows: [
            [1,          0,           0, 0],
            [0, cos(angle), -sin(angle), 0],
            [0, sin(angle),  cos(angle), 0],
            [0,          0,           0, 1]
        ])
        return rotation * matrix
    }
    
    static func rotateY(_ matrix: Mat4, _ angle: Float32) -> Mat4 {
        let rotation = Mat4(rows: [
            [ cos(angle),  0, sin(angle), 0],
            [          0,  1,          0, 0],
            [-sin(angle),  0, cos(angle), 0],
            [          0,  0,          0, 1]
        ])
        return rotation * matrix
    }
    
    static func rotate(_ matrix: Mat4, _ angle: Float32, _ axis: Vec3) -> Mat4 {
        let rotation = Mat4.rotation(axis: axis, angle: angle)
        return rotation * matrix
    }

    static func rotation(axis: Vec3, angle: Float32) -> Mat4 {
        let normalizedAxis = normalize(axis)
        let x = normalizedAxis.x
        let y = normalizedAxis.y
        let z = normalizedAxis.z

        let c = cos(angle)
        let s = sin(angle)
        let t = 1 - c

        let m00 = c + x * x * t
        let m01 = x * y * t - z * s
        let m02 = x * z * t + y * s

        let m10 = y * x * t + z * s
        let m11 = c + y * y * t
        let m12 = y * z * t - x * s

        let m20 = z * x * t - y * s
        let m21 = z * y * t + x * s
        let m22 = c + z * z * t

        return Mat4(
            Vec4(m00, m01, m02, 0),
            Vec4(m10, m11, m12, 0),
            Vec4(m20, m21, m22, 0),
            Vec4(0, 0, 0, 1)
        )
    }

    static func lookAt(
        position: Vec3,
        target: Vec3,
        up: Vec3
    ) -> Mat4 {
        let z = simd.normalize(position - target)
        let x = simd.normalize(simd.cross(up, z))
        let y = simd.normalize(simd.cross(z, x))
        
        return simd_float4x4(
            [                   x.x,                    y.x,                    z.x, 0],
            [                   x.y,                    y.y,                    z.y, 0],
            [                   x.z,                    y.z,                    z.z, 0],
            [-simd.dot(x, position), -simd.dot(y, position), -simd.dot(z, position), 1]
        )
    }
    
    static func orthographicProjection(
        left: Float32,
        right: Float32,
        top: Float32,
        bottom: Float32,
        near: Float32,
        far: Float32
    ) -> Mat4 {
        let sx = 2 / (right - left)
        let sy = 2 / (top - bottom)
        let sz = 1 / (near - far)
        let tx = (left + right) / (left - right)
        let ty = (top + bottom) / (bottom - top)
        let tz = near / (near - far)
        return Mat4(
            Vec4(sx,  0,  0, 0),
            Vec4( 0, sy,  0, 0),
            Vec4( 0,  0, sz, 0),
            Vec4(tx, ty, tz, 1)
        )
    }
    
    static func perspectiveProjection(
        fov: Float32,
        aspect: Float32,
        near: Float32,
        far: Float32
    ) -> Mat4 {
        let sy = 1 / tan(fov * 0.5)
        let sx = sy / aspect
        let zRange = far - near
        let sz = -(far + near) / zRange
        let tz = -2 * far * near / zRange
        return Mat4(
            Vec4(sx, 0,  0,  0),
            Vec4(0, sy,  0,  0),
            Vec4(0,  0, sz, -1),
            Vec4(0,  0, tz,  0)
        )
    }

    func formattedString() -> String {
        let rows = [
            self.transpose.columns.0,
            self.transpose.columns.1,
            self.transpose.columns.2,
            self.transpose.columns.3
        ]

        var matString = "["
        for i in 0..<4 {
            if i > 0 { matString += " "}
            
            matString += "["
            for j in 0..<4 {
                if j > 0 { matString += " " }
                
                let value = rows[i][j]
                if value >= 0 { matString += " " }
                matString += String(format: "%.4f", value)
            }
            
            matString += "]"
            if i < 3 {
                matString += ",\n"
            }
            
        }
        matString += "]"
        return matString;
    }
}
