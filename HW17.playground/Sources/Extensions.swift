import Foundation

// MARK: - Current time as h.m.ss.s

extension String {
    public static func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm:ss.SSSS"
        return formatter.string(from: Date())
    }
}
