// One-shot SwiftUI → PNG renderer for the Farkle "Trio" app icon.
//
// Run from the repo root:
//
//   swift tools/generate-icons.swift
//
// Writes PNGs at every iOS app-icon size into
// `Farkle/Resources/Assets.xcassets/AppIcon.appiconset/`.
// Output path can be overridden via the first CLI argument.
//
// Art derived from the Trio Icon design bundle:
//   - 1024×1024 canvas
//   - Cream paper background + walnut radial vignette
//   - Three bone dice: face 5 back, face 3 middle, face 1 front
//   - Each die has gradient fill, top highlight, bottom inner shadow,
//     and a blurred drop shadow

import SwiftUI
import AppKit

// MARK: - Colors

private let paper = Color(red: 0.953, green: 0.929, blue: 0.878)        // #f3ede0
private let walnut = Color(red: 0.357, green: 0.227, blue: 0.122)       // #5b3a1f
private let pipInner = Color(red: 0.353, green: 0.271, blue: 0.188)
private let pipOuter = Color(red: 0.102, green: 0.071, blue: 0.039)     // ~#1a120a

private let boneTop = Color(red: 0.996, green: 0.984, blue: 0.953)      // #fefbf3
private let boneMid = Color(red: 0.980, green: 0.965, blue: 0.933)      // #faf6ee
private let boneBottom = Color(red: 0.925, green: 0.890, blue: 0.812)   // #ece3cf

// MARK: - Pip layout

private func pipPositions(face: Int) -> [(Int, Int)] {
    switch face {
    case 1: return [(2,2)]
    case 2: return [(1,1),(3,3)]
    case 3: return [(1,1),(2,2),(3,3)]
    case 4: return [(1,1),(1,3),(3,1),(3,3)]
    case 5: return [(1,1),(1,3),(2,2),(3,1),(3,3)]
    case 6: return [(1,1),(1,2),(1,3),(3,1),(3,2),(3,3)]
    default: return []
    }
}

// MARK: - Die

private struct Die: View {
    let face: Int
    let side: CGFloat

    var body: some View {
        let r = side * 0.18
        ZStack {
            // Face
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(LinearGradient(
                    stops: [
                        .init(color: boneTop, location: 0),
                        .init(color: boneMid, location: 0.6),
                        .init(color: boneBottom, location: 1.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: side, height: side)
                .overlay(
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .stroke(walnut.opacity(0.10), lineWidth: side * 0.0055)
                )

            // Top highlight
            RoundedRectangle(cornerRadius: r * 0.85, style: .continuous)
                .fill(Color.white.opacity(0.45 * 0.55))
                .frame(width: side * 0.92, height: side * 0.42)
                .offset(y: -side * 0.27)

            // Bottom inner shadow strip
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color(red: 0.471, green: 0.392, blue: 0.275).opacity(0.10))
                .frame(width: side, height: side * 0.24)
                .offset(y: side * 0.38)
                .mask(RoundedRectangle(cornerRadius: r, style: .continuous)
                        .frame(width: side, height: side))

            // Pips
            ForEach(Array(pipPositions(face: face).enumerated()), id: \.offset) { _, pos in
                let pipSide = side * 0.13
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: pipInner, location: 0),
                            .init(color: pipOuter, location: 1.0)
                        ]),
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: pipSide
                    ))
                    .frame(width: pipSide, height: pipSide)
                    .position(
                        x: side * (CGFloat(pos.0 - 1) * 0.35 + 0.175),
                        y: side * (CGFloat(pos.1 - 1) * 0.35 + 0.175)
                    )
            }
        }
        .frame(width: side, height: side)
        // Drop shadow approximating SVG's feGaussianBlur stdDeviation=14
        .background(
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .frame(width: side, height: side)
                .blur(radius: side * 14.0 / 360.0)
                .offset(x: side * 0.05, y: side * 0.10)
        )
    }
}

// MARK: - Trio icon

private struct TrioIcon: View {
    var size: CGFloat = 1024

    private struct LayoutItem {
        let face: Int
        let x: CGFloat   // top-left in 1024 space
        let y: CGFloat
        let s: CGFloat   // side in 1024 space
        let rotate: Double
    }

    private let layout: [LayoutItem] = [
        .init(face: 5, x: 140, y: 520, s: 360, rotate: -12),
        .init(face: 3, x: 520, y: 480, s: 360, rotate: 8),
        .init(face: 1, x: 332, y: 180, s: 360, rotate: -3)
    ]

    var body: some View {
        let k = size / 1024.0
        ZStack {
            // Paper base
            paper

            // Soft vignette
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.6),
                    .init(color: walnut.opacity(0.18), location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 720 * k
            )

            // Dice stacked back → front
            ForEach(Array(layout.enumerated()), id: \.offset) { _, item in
                Die(face: item.face, side: item.s * k)
                    .rotationEffect(.degrees(item.rotate))
                    .position(x: (item.x + item.s / 2) * k,
                              y: (item.y + item.s / 2) * k)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Renderer

@MainActor
private func renderAll(into directory: URL) {
    let sizes: [Int] = [29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    for size in sizes {
        let name = "Icon-\(size).png"
        let renderer = ImageRenderer(content: TrioIcon(size: CGFloat(size)))
        renderer.scale = 1
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write("Failed to render \(name)\n".data(using: .utf8)!)
            continue
        }
        let url = directory.appendingPathComponent(name)
        do {
            try png.write(to: url)
            print("Wrote \(url.path) (\(png.count) bytes)")
        } catch {
            FileHandle.standardError.write("Failed to write \(name): \(error)\n".data(using: .utf8)!)
        }
    }
}

let outDir: URL = {
    if CommandLine.arguments.count > 1 {
        return URL(fileURLWithPath: CommandLine.arguments[1])
    }
    let cwd = FileManager.default.currentDirectoryPath
    return URL(fileURLWithPath: cwd)
        .appendingPathComponent("Farkle/Resources/Assets.xcassets/AppIcon.appiconset")
}()

if !FileManager.default.fileExists(atPath: outDir.path) {
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
}

print("Rendering icons into \(outDir.path)")
DispatchQueue.main.async {
    renderAll(into: outDir)
    exit(0)
}
RunLoop.main.run()
