extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let col0 = try container.decode(simd_float4.self)
        let col1 = try container.decode(simd_float4.self)
        let col2 = try container.decode(simd_float4.self)
        let col3 = try container.decode(simd_float4.self)
        self.init(col0, col1, col2, col3)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(columns.0)
        try container.encode(columns.1)
        try container.encode(columns.2)
        try container.encode(columns.3)
    }
}
