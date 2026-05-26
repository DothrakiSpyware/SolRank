import Foundation

/// Build / release configuration read from Info.plist plus beta flags.
enum AppConfig {
    static let appVersion: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber: String =
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let isBeta: Bool = true
    static let feedbackEmail: String = "feedback@solrank.app"

    static var versionString: String { "Version \(appVersion) (Build \(buildNumber))" }
}
