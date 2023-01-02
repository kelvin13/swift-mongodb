// swift-tools-version:5.7
import PackageDescription

let package:Package = .init(name: "swift-mongodb",
    products: 
    [
        .library(name: "BSON", targets: ["BSON"]),
        .library(name: "BSONDecoding", targets: ["BSONDecoding"]),
        .library(name: "BSONEncoding", targets: ["BSONEncoding"]),
        .library(name: "BSONSchema", targets: ["BSONSchema"]),
        .library(name: "BSONUnions", targets: ["BSONUnions"]),
        .library(name: "BSON_UUID", targets: ["BSON_UUID"]),

        .library(name: "Heartbeats", targets: ["Heartbeats"]),

        .library(name: "MongoDB", targets: ["MongoDB"]),
        .library(name: "MongoChannel", targets: ["MongoChannel"]),
        .library(name: "MongoConnection", targets: ["MongoConnection"]),
        .library(name: "MongoSchema", targets: ["MongoSchema"]),
        .library(name: "MongoDriver", targets: ["MongoDriver"]),
        .library(name: "MongoTopology", targets: ["MongoTopology"]),
        .library(name: "MongoWire", targets: ["MongoWire"]),

        .library(name: "SCRAM", targets: ["SCRAM"]),
        .library(name: "TraceableErrors", targets: ["TraceableErrors"]),
        .library(name: "UUID", targets: ["UUID"]),
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/swift-hash", .upToNextMinor(from: "0.4.4")),
        
        // this is used to generate `Sources/BSONDecoding/Decoder/Decoder.spf.swift`
        .package(url: "https://github.com/kelvin13/swift-package-factory.git",
            revision: "swift-DEVELOPMENT-SNAPSHOT-2022-12-17-a"),
        
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMinor(from: "2.46.0")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMinor(from: "2.23.0")),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.3"),
    ],
    targets:
    [
        .target(name: "TraceableErrors"),

        .target(name: "UUID",
            dependencies:
            [
                .product(name: "Base16", package: "swift-hash"),
            ]),

        .target(name: "BSONTraversal"),
        .target(name: "BSON",
            dependencies:
            [
                .target(name: "BSONTraversal"),
            ]),
        .target(name: "BSONDecoding",
            dependencies:
            [
                .target(name: "BSONUnions"),
                .target(name: "TraceableErrors"),
            ]),
        .target(name: "BSONEncoding",
            dependencies:
            [
                .target(name: "BSON"),
            ]),
        .target(name: "BSONSchema",
            dependencies:
            [
                .target(name: "BSONDecoding"),
                .target(name: "BSONEncoding"),
            ]),
        .target(name: "BSONUnions",
            dependencies:
            [
                .target(name: "BSON"),
            ]),
        .target(name: "BSON_UUID",
            dependencies:
            [
                .target(name: "BSONSchema"),
                .target(name: "UUID"),
            ]),
        .target(name: "BSON_Durations",
            dependencies:
            [
                .target(name: "BSONSchema"),
                .target(name: "Durations"),
            ]),
        
        .target(name: "Durations"),
        
        .target(name: "Heartbeats"),
        
        .target(name: "SCRAM",
            dependencies: 
            [
                .product(name: "Base64",                package: "swift-hash"),
                .product(name: "MessageAuthentication", package: "swift-hash"),
            ]),

        // the mongo wire protocol. has no awareness of networking or
        // driver-level concepts.
        .target(name: "MongoWire",
            dependencies: 
            [
                .target(name: "BSON"),
                .product(name: "CRC", package: "swift-hash"),
            ]),
        
        // basic type definitions and conformances. driver peripherals can
        // import this instead of ``/MongoDriver`` to avoid depending on `swift-nio`.
        .target(name: "Mongo",
            dependencies: 
            [
                // this dependency is here because we need several of the
                // enumeration types to be ``BSONDecodable`` and ``BSONEncodable``,
                // and we do not want a downstream module to have to declare
                // retroactive conformances.
                .target(name: "BSONSchema"),
            ]),

        .target(name: "MongoChannel",
            dependencies: 
            [
                .target(name: "BSONSchema"),
                .target(name: "Heartbeats"),
                .target(name: "MongoWire"),
                .target(name: "TraceableErrors"),
                .product(name: "NIOCore",               package: "swift-nio"),
                .product(name: "Atomics",               package: "swift-atomics"),
            ]),

        .target(name: "MongoConnection",
            dependencies:
            [
                .target(name: "MongoChannel"),
            ]),

        .target(name: "MongoTopology",
            dependencies:
            [
                .target(name: "MongoConnection"),
            ]),

        .target(name: "MongoDriver",
            dependencies: 
            [
                .target(name: "BSON_UUID"),
                .target(name: "BSON_Durations"),
                .target(name: "Mongo"),
                .target(name: "MongoChannel"),
                .target(name: "MongoTopology"),
                .target(name: "SCRAM"),
                .product(name: "SHA2",                  package: "swift-hash"),
                // already included by `MongoTopology`’s transitive `Atomics` dependency,
                // but restated here for clarity.
                .product(name: "Atomics",               package: "swift-atomics"),
                // already included by `MongoTopology`’s transitive `NIOCore` dependency,
                // but restated here for clarity.
                .product(name: "NIOCore",               package: "swift-nio"),
                .product(name: "NIOPosix",              package: "swift-nio"),
                .product(name: "NIOSSL",                package: "swift-nio-ssl"),
            ]),
        
        .target(name: "MongoSchema",
            dependencies: 
            [
                .target(name: "BSONSchema"),
            ]),
        
        .target(name: "MongoDB",
            dependencies: 
            [
                .target(name: "MongoDriver"),
                .target(name: "MongoSchema"),
            ]),

        // connection uri strings.
        .target(name: "MongoURI",
            dependencies: 
            [
                .target(name: "Durations"),
                .target(name: "Mongo"),
                .target(name: "MongoTopology"),
            ]),
        

        .executableTarget(name: "BSONTests",
            dependencies:
            [
                .target(name: "BSONUnions"),
                .product(name: "Base16", package: "swift-hash"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/BSON"),
        
        .executableTarget(name: "BSONDecodingTests",
            dependencies:
            [
                .target(name: "BSONDecoding"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/BSONDecoding"),
        
        .executableTarget(name: "BSONEncodingTests",
            dependencies:
            [
                .target(name: "BSONEncoding"),
                .target(name: "BSONUnions"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/BSONEncoding"),
        
        .executableTarget(name: "HeartbeatsTests",
            dependencies:
            [
                .target(name: "Heartbeats"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/Heartbeats"),
        
        .executableTarget(name: "MongoDBTests",
            dependencies:
            [
                .target(name: "MongoDB"),
                // already included by `MongoDriver`’s transitive `NIOSSL` dependency,
                // but restated here for clarity.
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/MongoDB"),
        
        .executableTarget(name: "MongoDriverTests",
            dependencies:
            [
                .target(name: "MongoDriver"),
                // already included by `MongoDriver`’s transitive `NIOSSL` dependency,
                // but restated here for clarity.
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Testing", package: "swift-hash"),
            ], 
            path: "Tests/MongoDriver"),
    ]
)
