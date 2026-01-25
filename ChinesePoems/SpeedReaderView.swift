//
//  SpeedReaderView.swift
//  ChinesePoems
//
//  Speed reader for character-by-character Chinese reading
//

import SwiftUI

// MARK: - Speed Reader Manager

@MainActor
class SpeedReaderManager: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var characters: [Character] = []

    @AppStorage("speedReaderCPM") var cpm: Int = 120 // Characters per minute

    private var timer: Timer?

    var msPerCharacter: Double {
        60000.0 / Double(cpm)
    }

    var currentCharacter: Character? {
        guard currentIndex >= 0 && currentIndex < characters.count else { return nil }
        return characters[currentIndex]
    }

    var progress: Double {
        guard !characters.isEmpty else { return 0 }
        return Double(currentIndex) / Double(characters.count - 1)
    }

    var estimatedTimeRemaining: Int {
        let remaining = characters.count - currentIndex
        return Int(Double(remaining) * msPerCharacter / 1000)
    }

    func loadText(_ text: String) {
        // Filter out spaces and newlines, keep only meaningful characters
        characters = text.filter { !$0.isWhitespace }.map { $0 }
        currentIndex = 0
    }

    func play() {
        guard !characters.isEmpty && currentIndex < characters.count else { return }
        isPlaying = true
        scheduleNextCharacter()
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func nextCharacter() {
        guard currentIndex < characters.count - 1 else {
            pause()
            return
        }
        currentIndex += 1
        if isPlaying { scheduleNextCharacter() }
    }

    func previousCharacter() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func skipForward(_ count: Int = 10) {
        currentIndex = min(currentIndex + count, characters.count - 1)
    }

    func skipBackward(_ count: Int = 10) {
        currentIndex = max(currentIndex - count, 0)
    }

    func restart() {
        currentIndex = 0
        if isPlaying {
            scheduleNextCharacter()
        }
    }

    func setCPM(_ newCPM: Int) {
        cpm = max(10, min(600, newCPM))
        if isPlaying {
            timer?.invalidate()
            scheduleNextCharacter()
        }
    }

    private func scheduleNextCharacter() {
        timer?.invalidate()

        var delay = msPerCharacter / 1000.0

        // Add extra pause for punctuation
        if let char = currentCharacter {
            let punctuation = "。！？，、；：「」『』"
            if punctuation.contains(char) {
                delay *= 2.0
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.nextCharacter()
            }
        }
    }
}

// MARK: - CPM Presets

enum CPMPreset: Int, CaseIterable {
    case slow = 60
    case normal = 120
    case fast = 200
    case turbo = 300

    var label: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        case .turbo: return "Turbo"
        }
    }

    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "figure.walk"
        case .fast: return "hare.fill"
        case .turbo: return "bolt.fill"
        }
    }
}

// MARK: - Speed Reader View

struct SpeedReaderView: View {
    let poem: Poem
    let pinyinDictionary: [String: DictionaryEntry]

    @StateObject private var manager = SpeedReaderManager()
    @State private var showPinyin = true
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar with title and close
                    topBar

                    Spacer()

                    // Main character display
                    characterDisplay

                    Spacer()

                    // Bottom controls
                    if showControls {
                        bottomControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls.toggle()
                }
                if showControls && manager.isPlaying {
                    showControlsTemporarily()
                }
            }
            .gesture(swipeGesture)
        }
        .onAppear {
            manager.loadText(poem.content)
        }
        .onDisappear {
            manager.pause()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text(poem.title_chinese)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button(action: { showPinyin.toggle() }) {
                Text(showPinyin ? "拼" : "拼")
                    .font(.headline)
                    .foregroundColor(showPinyin ? .green : .white.opacity(0.5))
                    .padding(8)
                    .background(showPinyin ? Color.green.opacity(0.2) : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Character Display

    private var characterDisplay: some View {
        VStack(spacing: 24) {
            // Pinyin above
            if showPinyin, let char = manager.currentCharacter {
                let charStr = String(char)
                if let entry = pinyinDictionary[charStr] {
                    Text(entry.pinyin_tone_lines)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            // Main character with focus indicator
            HStack(spacing: 0) {
                if let char = manager.currentCharacter {
                    Text(String(char))
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("開始")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Progress indicator
            Text("\(manager.currentIndex + 1) / \(manager.characters.count)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Progress bar
            ProgressView(value: manager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .padding(.horizontal)

            // Playback controls
            HStack(spacing: 32) {
                Button(action: { manager.skipBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: { manager.previousCharacter() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: { manager.togglePlayPause() }) {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }

                Button(action: { manager.nextCharacter() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: { manager.skipForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }

            // Speed controls
            VStack(spacing: 8) {
                HStack {
                    Text("\(manager.cpm) CPM")
                        .font(.caption)
                        .foregroundColor(.white)

                    Spacer()

                    Text(formatTime(manager.estimatedTimeRemaining))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Slider(
                    value: Binding(
                        get: { Double(manager.cpm) },
                        set: { manager.setCPM(Int($0)) }
                    ),
                    in: 30...400,
                    step: 10
                )
                .tint(.green)

                // Preset buttons
                HStack(spacing: 12) {
                    ForEach(CPMPreset.allCases, id: \.rawValue) { preset in
                        Button(action: { manager.setCPM(preset.rawValue) }) {
                            VStack(spacing: 4) {
                                Image(systemName: preset.icon)
                                    .font(.caption)
                                Text(preset.label)
                                    .font(.caption2)
                            }
                            .foregroundColor(manager.cpm == preset.rawValue ? .green : .white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(manager.cpm == preset.rawValue ? Color.green.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.black.opacity(0.7))
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                if abs(horizontal) > abs(vertical) {
                    if horizontal > 0 {
                        manager.skipBackward(5)
                    } else {
                        manager.skipForward(5)
                    }
                } else if vertical > 0 {
                    dismiss()
                }
            }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func showControlsTemporarily() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if manager.isPlaying {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
}

#Preview {
    SpeedReaderView(
        poem: Poem(
            id: "1",
            title_chinese: "靜夜思",
            title: "Quiet Night Thought",
            author_chinese: "李白",
            author: "Li Bai",
            content: "床前明月光 疑是地上霜 舉頭望明月 低頭思故鄉",
            translation_english: "Before my bed, bright moonlight shines..."
        ),
        pinyinDictionary: [:]
    )
}
