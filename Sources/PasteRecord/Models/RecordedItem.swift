import Foundation

struct RecordedItem: Identifiable, Equatable {
    let id = UUID()
    var content: String
    let capturedAt: Date

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let single = trimmed.replacingOccurrences(of: "\n", with: " ")
        if single.count <= 60 { return single }
        return String(single.prefix(60)) + "…"
    }
}
