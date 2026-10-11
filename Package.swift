// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ComposeEditor",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ComposeEditor",
            targets: ["ComposeEditor"]),
        .library(
            name: "TokenTextView",
            targets: ["TokenTextView"]),
        .library(
            name: "ComposeEditorTokenBuiltins",
            targets: ["ComposeEditorTokenBuiltins"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TextEditor"),
        .target(
            name: "TokenTextView",
            dependencies: ["TextEditor"]),
        .target(
            name: "ComposeEditor",
            dependencies: ["TokenTextView"]),
        .target(
            name: "ComposeEditorTokenBuiltins",
            dependencies: ["TokenTextView"]),
        .testTarget(
            name: "ComposeEditorTests",
            dependencies: ["ComposeEditor", "TextEditor"]),
        .testTarget(
            name: "TokenTextViewTests",
            dependencies: ["TokenTextView", "ComposeEditorTokenBuiltins", "TextEditor"]),
    ]
)
