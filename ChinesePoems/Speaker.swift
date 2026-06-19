//
//  Speaker.swift
//  ChinesePoems
//
//  Text-to-speech for Chinese, shared across the dictionary, flashcards, and
//  the reader's read-aloud mode. Uses iOS' built-in voices (no network).
//

import AVFoundation
import SwiftUI

@MainActor
final class Speaker: ObservableObject {
    static let shared = Speaker()

    private let synth = AVSpeechSynthesizer()

    /// Speak a word or character. `traditional` only nudges the accent
    /// (zh-TW vs zh-CN); both read either script.
    func speak(_ text: String, traditional: Bool, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        configureSession()
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: traditional ? "zh-TW" : "zh-CN")
        utterance.rate = rate
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
        #endif
    }
}

/// A small reusable 🔊 button.
struct SpeakButton: View {
    let text: String
    let traditional: Bool
    var size: CGFloat = 20

    var body: some View {
        Button {
            Speaker.shared.speak(text, traditional: traditional)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size))
                .foregroundColor(Theme.inkFaded)
        }
        .buttonStyle(.plain)
    }
}
