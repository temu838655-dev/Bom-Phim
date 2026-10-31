import Foundation

struct SubtitleCue: Identifiable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

enum SubtitleParser {
    static func parse(_ content: String) -> [SubtitleCue] {
        let normalized = content
            .replacingOccurrences(of: "\\r\\n", with: "\\n")
            .replacingOccurrences(of: "\\r", with: "\\n")
            .replacingOccurrences(of: "\\u{FEFF}", with: "")
        let lines = normalized.components(separatedBy: "\\n")
        var blocks: [[String]] = []
        var currentBlock: [String] = []

        // Treat blank lines containing spaces/tabs as cue separators too.
        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock)
                    currentBlock = []
                }
            } else {
                currentBlock.append(line)
            }
        }
        if !currentBlock.isEmpty { blocks.append(currentBlock) }

        var cues: [SubtitleCue] = []
        for (index, block) in blocks.enumerated() {
            guard let timingIndex = block.firstIndex(where: { $0.contains("-->") }) else { continue }
            let parts = block[timingIndex].components(separatedBy: "-->")
            guard parts.count == 2,
                  let start = parseTime(parts[0]),
                  let end = parseTime(parts[1]),
                  end > start else { continue }

            let text = block.dropFirst(timingIndex + 1)
                .joined(separator: "\\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            cues.append(SubtitleCue(id: index, start: start, end: end, text: text))
        }
        return cues.sorted { $0.start < $1.start }
    }

    private static func parseTime(_ raw: String) -> TimeInterval? {
        let timestamp = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .first ?? ""
        let normalized = timestamp.replacingOccurrences(of: ",", with: ".")
        let parts = normalized.components(separatedBy: ":")
        guard parts.count == 2 || parts.count == 3 else { return nil }

        let hours: Double
        let minutes: Double
        let seconds: Double
        if parts.count == 3 {
            guard let h = Double(parts[0]), let m = Double(parts[1]), let s = Double(parts[2]) else { return nil }
            hours = h
            minutes = m
            seconds = s
        } else {
            guard let m = Double(parts[0]), let s = Double(parts[1]) else { return nil }
            hours = 0
            minutes = m
            seconds = s
        }
        guard hours >= 0, minutes >= 0, minutes < 60, seconds >= 0, seconds < 60 else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }
}
