//
//  Audiobook.swift
//  ChinesePoems
//
//  聽書 — read-aloud / audiobook mode. Speaks a text line by line with the
//  current line highlighted, play/pause, line skip, and a speed control.
//

import AVFoundation
import SwiftUI

@MainActor
final class AudiobookManager: NSObject, ObservableObject {
    @Published var currentLine = 0
    @Published var isPlaying = false
    @AppStorage("audiobookRate") private var storedRate: Double = Double(AVSpeechUtteranceDefaultSpeechRate)

    private(set) var lines: [String] = []
    private var traditional = true
    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    var rate: Float { Float(storedRate) }

    func load(_ text: String, traditional: Bool) {
        lines = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).map(String.init)
        self.traditional = traditional
        currentLine = 0
    }

    func play() {
        guard !lines.isEmpty else { return }
        configureSession()
        isPlaying = true
        speakCurrent()
    }

    func pause() {
        isPlaying = false
        synth.stopSpeaking(at: .immediate)
    }

    func toggle() { isPlaying ? pause() : play() }

    func next() { guard currentLine < lines.count - 1 else { return }; jump(to: currentLine + 1) }
    func previous() { guard currentLine > 0 else { return }; jump(to: currentLine - 1) }

    func jump(to index: Int) {
        synth.stopSpeaking(at: .immediate)   // fires didCancel (ignored), not didFinish
        currentLine = index
        if isPlaying { speakCurrent() }
    }

    func setRate(_ r: Float) {
        storedRate = Double(r)
        if isPlaying {
            synth.stopSpeaking(at: .immediate)
            speakCurrent()
        }
    }

    private func speakCurrent() {
        guard currentLine < lines.count else { isPlaying = false; return }
        let utterance = AVSpeechUtterance(string: lines[currentLine])
        utterance.voice = AVSpeechSynthesisVoice(language: traditional ? "zh-TW" : "zh-CN")
        utterance.rate = rate
        synth.speak(utterance)
    }

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
        #endif
    }
}

extension AudiobookManager: AVSpeechSynthesizerDelegate {
    // Only natural completion advances; manual stops fire didCancel instead.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.isPlaying else { return }
            if self.currentLine < self.lines.count - 1 {
                self.currentLine += 1
                self.speakCurrent()
            } else {
                self.isPlaying = false
            }
        }
    }
}

struct AudiobookView: View {
    let poem: Poem
    let traditional: Bool

    @StateObject private var manager = AudiobookManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        ForEach(Array(manager.lines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(Theme.serif(index == manager.currentLine ? 30 : 24,
                                                  index == manager.currentLine ? .semibold : .regular))
                                .foregroundColor(index == manager.currentLine ? Theme.cinnabar : Theme.inkFaded)
                                .id(index)
                                .onTapGesture { manager.jump(to: index) }
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: manager.currentLine) { _, line in
                    withAnimation(.easeInOut) { proxy.scrollTo(line, anchor: .center) }
                }
            }

            controls
        }
        .paperBackground()
        .onAppear { manager.load(poem.content(simplified: !traditional), traditional: traditional) }
        .onDisappear { manager.pause() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.inkFaded)
            }
            Spacer()
            Text(poem.titleChinese(simplified: !traditional))
                .font(Theme.serif(17, .semibold))
                .foregroundColor(Theme.ink)
            Spacer()
            Image(systemName: "chevron.down").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 0.5), alignment: .bottom)
    }

    private var controls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 44) {
                Button { manager.previous() } label: {
                    Image(systemName: "backward.fill").font(.title2).foregroundColor(Theme.ink)
                }
                Button { manager.toggle() } label: {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Theme.cinnabar)
                }
                Button { manager.next() } label: {
                    Image(systemName: "forward.fill").font(.title2).foregroundColor(Theme.ink)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "tortoise.fill").font(.caption).foregroundColor(Theme.inkWhisper)
                Slider(
                    value: Binding(get: { Double(manager.rate) },
                                   set: { manager.setRate(Float($0)) }),
                    in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceDefaultSpeechRate)
                )
                .tint(Theme.cinnabar)
                Image(systemName: "hare.fill").font(.caption).foregroundColor(Theme.inkWhisper)
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 0.5), alignment: .top)
    }
}
