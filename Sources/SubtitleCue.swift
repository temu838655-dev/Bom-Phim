import Foundation

struct SubtitleCue: Identifiable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

enum SubtitleParser {
    static func parse(_ content: String) -> [SubtitleCue] {
        let normalized = content.replacingOccurrences(of: "\\r\\n", with: "\\n")
            .replacingOccurrences(of: "\\r", with: "\\n")
        let blocks = normalized.components(separatedBy: "\\n\\n")
        var cues: [SubtitleCue] = []
        for (index, block) in blocks.enumerated() {
            let lines = block.components(separatedBy: "\\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard let timeLine = lines.first(where: { $0.contains("-->") }) else { continue }
            let parts = timeLine.components(separatedBy: "-->")
            guard parts.count == 2,
                  let start = parseTime(parts[0]),
                  let end = parseTime(parts[1]) else { continue }
            let timeIndex = lines.firstIndex(of: timeLine) ?? 0
            let text = lines.dropFirst(timeIndex + 1).joined(separator: "\\n")
            guard !text.isEmpty else { continue }
            cues.append(SubtitleCue(id: index, start: start, end: end, text: text))
        }
        return cues.sorted { $0.start < $1.start }
    }

    private static func parseTime(_ raw: String) -> TimeInterval? {
        let value = raw.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        let parts = value.components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }
}
