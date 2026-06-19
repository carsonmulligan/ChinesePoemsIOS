//
//  StrokeOrder.swift
//  ChinesePoems
//
//  Animated stroke-order diagrams from Make Me a Hanzi data. Each stroke is a
//  filled SVG outline; the current stroke is revealed by sweeping a thick line
//  along its median (the hanzi-writer technique).
//

import SwiftUI

/// One character's graphics: SVG stroke outlines (`s`) and stroke medians (`m`).
/// Median coordinates are Double — a handful of entries use fractional values.
struct HanziGraphic: Codable {
    let s: [String]
    let m: [[[Double]]]
}

/// Radical (`r`) and component decomposition (`d`) for a character.
struct RadicalInfo: Codable {
    let r: String
    let d: String
}

// MARK: - Minimal SVG path parser (M / L / Q / C / Z, absolute, space-separated)

enum SVGPath {
    /// Parse a Make Me a Hanzi path into a Path, flipping y (their coords are y-up).
    static func parse(_ d: String) -> Path {
        var path = Path()
        let tokens = d.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
        var i = 0
        var cmd = ""
        func nextPoint() -> CGPoint {
            let x = CGFloat(Double(tokens[i]) ?? 0); i += 1
            let y = CGFloat(Double(tokens[i]) ?? 0); i += 1
            return CGPoint(x: x, y: -y)   // flip y-up → y-down
        }
        while i < tokens.count {
            if let first = tokens[i].first, first.isLetter {
                cmd = tokens[i]; i += 1
                if cmd == "Z" || cmd == "z" { path.closeSubpath() }
                continue
            }
            switch cmd {
            case "M": path.move(to: nextPoint())
            case "L": path.addLine(to: nextPoint())
            case "Q":
                let c = nextPoint(); let p = nextPoint()
                path.addQuadCurve(to: p, control: c)
            case "C":
                let c1 = nextPoint(); let c2 = nextPoint(); let p = nextPoint()
                path.addCurve(to: p, control1: c1, control2: c2)
            default:
                i += 1   // skip unknown token defensively
            }
        }
        return path
    }

    static func median(_ points: [[Double]]) -> Path {
        var path = Path()
        guard let first = points.first, first.count >= 2 else { return path }
        path.move(to: CGPoint(x: first[0], y: -first[1]))
        for p in points.dropFirst() where p.count >= 2 {
            path.addLine(to: CGPoint(x: p[0], y: -p[1]))
        }
        return path
    }
}

// MARK: - Animated stroke-order view

struct StrokeOrderView: View {
    let graphic: HanziGraphic

    private let strokes: [Path]
    private let medians: [Path]
    private let bounds: CGRect

    @State private var shown = 0           // fully drawn strokes
    @State private var progress: CGFloat = 0  // current stroke sweep 0…1

    init(graphic: HanziGraphic) {
        self.graphic = graphic
        let s = graphic.s.map(SVGPath.parse)
        self.strokes = s
        self.medians = graphic.m.map(SVGPath.median)
        self.bounds = s.reduce(CGRect.null) { $0.union($1.boundingRect) }
    }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let tf = fitTransform(into: rect, pad: 14)
            let lineWidth = 230 * scale(into: rect, pad: 14)

            ZStack {
                ForEach(strokes.indices, id: \.self) { idx in
                    let filled = strokes[idx].applying(tf)
                    if idx < shown {
                        filled.fill(Theme.ink)
                    } else if idx == shown {
                        // Fill the active stroke in the same ink as completed ones
                        // so it just grows in, rather than flashing a colour.
                        let medianPath = (medians[safe: idx] ?? Path()).applying(tf)
                        filled.fill(Theme.ink)
                            .mask {
                                StaticShape(path: medianPath)
                                    .trim(from: 0, to: progress)
                                    .stroke(Color.white, style: StrokeStyle(
                                        lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                            }
                    } else {
                        filled.fill(Theme.inkWhisper)   // visible guide for upcoming strokes
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { restart() }
    }

    private func restart() {
        shown = 0; progress = 0
        playNext()
    }

    private func playNext() {
        guard shown < strokes.count else { return }
        progress = 0
        withAnimation(.linear(duration: 0.65)) {
            progress = 1
        } completion: {
            shown += 1
            if shown < strokes.count { playNext() }
        }
    }

    // Fit the glyph bounds into the rect (aspect-fit, centered).
    private func scale(into rect: CGRect, pad: CGFloat) -> CGFloat {
        let avail = rect.insetBy(dx: pad, dy: pad)
        guard bounds.width > 0, bounds.height > 0 else { return 1 }
        return min(avail.width / bounds.width, avail.height / bounds.height)
    }

    private func fitTransform(into rect: CGRect, pad: CGFloat) -> CGAffineTransform {
        let s = scale(into: rect, pad: pad)
        let tx = rect.midX - bounds.midX * s
        let ty = rect.midY - bounds.midY * s
        return CGAffineTransform(translationX: tx, y: ty).scaledBy(x: s, y: s)
    }
}

// MARK: - Full-screen stroke viewer

struct StrokeFullScreenView: View {
    let term: String
    let graphic: HanziGraphic
    @Environment(\.dismiss) private var dismiss
    @State private var replay = 0

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.inkFaded)
                }
                Spacer()
                Text("\(term) · \(graphic.s.count) 筆")
                    .font(Theme.serif(17, .semibold)).foregroundColor(Theme.ink)
                Spacer()
                Image(systemName: "xmark").opacity(0)
            }
            .padding(.horizontal, 20).padding(.top, 16)

            Spacer()
            StrokeOrderView(graphic: graphic)
                .id(replay)
                .frame(width: 300, height: 300)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.paperSunken))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
            Spacer()

            Button { replay += 1 } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("重播 · Replay").font(Theme.serif(16, .medium))
                }
                .foregroundColor(Color(hex: 0xFBF5E6))
                .padding(.horizontal, 28).padding(.vertical, 13)
                .background(Capsule().fill(Theme.cinnabar))
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
    }
}

// MARK: - Helpers

/// A Shape that returns a fixed pre-transformed path, so `.trim` can animate it.
private struct StaticShape: Shape {
    let path: Path
    func path(in rect: CGRect) -> Path { path }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
