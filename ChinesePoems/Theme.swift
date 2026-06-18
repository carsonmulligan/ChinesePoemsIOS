//
//  Theme.swift
//  ChinesePoems
//
//  "Rice paper & cinnabar" (宣紙與朱紅) design system.
//  Warm cream ground, ink-black serif, a single cinnabar accent used like a
//  seal stamp. Light-first with a warm, aged-lacquer dark mode.
//

import SwiftUI
import UIKit

// MARK: - Dynamic color helper

extension Color {
    /// Build a color that resolves differently in light vs. dark mode.
    init(light: UIColor, dark: UIColor) {
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Palette

enum Theme {
    /// Page ground — warm xuan paper.
    static let paper = Color(light: UIColor(hex: 0xF4ECD8), dark: UIColor(hex: 0x1A1714))
    /// Slightly raised surface (cards, strips).
    static let paperRaised = Color(light: UIColor(hex: 0xFBF5E6), dark: UIColor(hex: 0x241F18))
    /// A deeper recess (e.g. progress track).
    static let paperSunken = Color(light: UIColor(hex: 0xE7DCC2), dark: UIColor(hex: 0x14110E))

    /// Primary text — pine-soot ink.
    static let ink = Color(light: UIColor(hex: 0x1F1B16), dark: UIColor(hex: 0xECE3D2))
    /// Secondary text — faded ink.
    static let inkFaded = Color(light: UIColor(hex: 0x6E6253), dark: UIColor(hex: 0x9A9080))
    /// Tertiary — very light wash.
    static let inkWhisper = Color(light: UIColor(hex: 0xA89A82), dark: UIColor(hex: 0x6A6256))

    /// The single accent — cinnabar / 朱紅 (the seal).
    static let cinnabar = Color(light: UIColor(hex: 0xA8322A), dark: UIColor(hex: 0xCB5C49))
    static let cinnabarSoft = Color(light: UIColor(hex: 0xA8322A).withAlphaComponent(0.12),
                                    dark: UIColor(hex: 0xCB5C49).withAlphaComponent(0.18))

    /// Hairline rule.
    static let hairline = Color(light: UIColor(hex: 0x1F1B16).withAlphaComponent(0.12),
                                dark: UIColor(hex: 0xECE3D2).withAlphaComponent(0.14))

    // MARK: Type — printed-classic serif (宋體 / New York) throughout.

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Quiet UI labels (pinyin, captions) stay in a neutral rounded-less sans
    /// so Latin glyphs read cleanly at small sizes.
    static func label(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Reusable surfaces & marks

/// Fills the whole screen with paper and lets content scroll over it.
struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Theme.paper.ignoresSafeArea())
    }
}
extension View {
    func paperBackground() -> some View { modifier(PaperBackground()) }
}

/// A cinnabar seal square — the read/已讀 mark and accent stamp.
struct SealMark: View {
    var glyph: String = "讀"
    var size: CGFloat = 26
    var filled: Bool = true

    var body: some View {
        Text(glyph)
            .font(Theme.serif(size * 0.5, .semibold))
            .foregroundColor(filled ? Color(hex: 0xFBF5E6) : Theme.cinnabar)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(filled ? Theme.cinnabar : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.18)
                    .stroke(Theme.cinnabar, lineWidth: filled ? 0 : 1.4)
            )
    }
}

/// Thin cinnabar progress bar on a sunken paper track.
struct InkProgressBar: View {
    var value: Double   // 0...1
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.paperSunken)
                Capsule()
                    .fill(Theme.cinnabar)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

/// A section header: Chinese title, English subtitle, hairline under.
struct SectionHeader: View {
    let chinese: String
    var english: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(chinese)
                .font(Theme.serif(20, .semibold))
                .foregroundColor(Theme.ink)
            if let english {
                Text(english)
                    .font(Theme.label(12, .regular))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(Theme.inkWhisper)
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}

/// A short cinnabar tier badge (築基 / 進階 …).
struct TierBadge: View {
    let tier: CourseTier
    var body: some View {
        Text(tier.chinese)
            .font(Theme.serif(12, .medium))
            .foregroundColor(Theme.cinnabar)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.cinnabar.opacity(0.4), lineWidth: 1)
            )
    }
}
