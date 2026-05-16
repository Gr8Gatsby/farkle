// Renders the launch-screen logo (dice trio, transparent background) at 1x/2x/3x.
//
//   swift tools/generate-launch-logo.swift
//
// Output: Farkle/Resources/Assets.xcassets/LaunchLogo.imageset/LaunchLogo{,@2x,@3x}.png
// Plus the imageset's Contents.json.

import SwiftUI
import AppKit

private let walnut = Color(red: 0.357, green: 0.227, blue: 0.122)
private let pipInner = Color(red: 0.353, green: 0.271, blue: 0.188)
private let pipOuter = Color(red: 0.102, green: 0.071, blue: 0.039)
private let boneTop = Color(red: 0.996, green: 0.984, blue: 0.953)
private let boneMid = Color(red: 0.980, green: 0.965, blue: 0.933)
private let boneBottom = Color(red: 0.925, green: 0.890, blue: 0.812)

private func pipPositions(face: Int) -> [(Int, Int)] {
    switch face {
    case 1: return [(2,2)]
    case 2: return [(1,1),(3,3)]
    case 3: return [(1,1),(2,2),(3,3)]
    case 5: return [(1,1),(1,3),(2,2),(3,1),(3,3)]
    default: return []
    }
}

private struct Die: View {
    let face: Int
    let side: CGFloat
    var body: some View {
        let r = side * 0.18
        ZStack {
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
            RoundedRectangle(cornerRadius: r * 0.85, style: .continuous)
                .fill(Color.white.opacity(0.45 * 0.55))
                .frame(width: side * 0.92, height: side * 0.42)
                .offset(y: -side * 0.27)
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color(red: 0.471, green: 0.392, blue: 0.275).opacity(0.10))
                .frame(width: side, height: side * 0.24)
                .offset(y: side * 0.38)
                .mask(RoundedRectangle(cornerRadius: r, style: .continuous)
                        .frame(width: side, height: side))
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
        .background(
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .frame(width: side, height: side)
                .blur(radius: side * 14.0 / 360.0)
                .offset(x: side * 0.05, y: side * 0.10)
        )
    }
}

private struct LaunchLogo: View {
    var size: CGFloat
    var body: some View {
        let s = size / 1024.0
        ZStack {
            Color.clear
            // Slightly tighter spread than the icon — three dice grouped centrally
            Die(face: 5, side: 360 * s)
                .rotationEffect(.degrees(-12))
                .position(x: (140 + 180) * s, y: (520 + 180) * s)
            Die(face: 3, side: 360 * s)
                .rotationEffect(.degrees(8))
                .position(x: (520 + 180) * s, y: (480 + 180) * s)
            Die(face: 1, side: 360 * s)
                .rotationEffect(.degrees(-3))
                .position(x: (332 + 180) * s, y: (180 + 180) * s)
        }
        .frame(width: size, height: size)
    }
}

@MainActor
private func renderAll(into directory: URL) {
    let bases: [(scale: Int, suffix: String, px: Int)] = [
        (1, "",       512),
        (2, "@2x",   1024),
        (3, "@3x",   1536)
    ]
    for entry in bases {
        let renderer = ImageRenderer(content: LaunchLogo(size: CGFloat(entry.px)))
        renderer.scale = 1
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write("Failed to render LaunchLogo\(entry.suffix)\n".data(using: .utf8)!)
            continue
        }
        let name = "LaunchLogo\(entry.suffix).png"
        let url = directory.appendingPathComponent(name)
        try? png.write(to: url)
        print("Wrote \(url.path) — \(png.count) bytes")
    }
    // Contents.json
    let json = """
    {
      "images" : [
        { "idiom" : "universal", "filename" : "LaunchLogo.png", "scale" : "1x" },
        { "idiom" : "universal", "filename" : "LaunchLogo@2x.png", "scale" : "2x" },
        { "idiom" : "universal", "filename" : "LaunchLogo@3x.png", "scale" : "3x" }
      ],
      "info" : { "version" : 1, "author" : "xcode" }
    }
    """
    let manifest = directory.appendingPathComponent("Contents.json")
    try? json.data(using: .utf8)?.write(to: manifest)
    print("Wrote \(manifest.path)")
}

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Farkle/Resources/Assets.xcassets/LaunchLogo.imageset")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
print("Rendering launch logo into \(outDir.path)")
DispatchQueue.main.async {
    renderAll(into: outDir)
    exit(0)
}
RunLoop.main.run()
