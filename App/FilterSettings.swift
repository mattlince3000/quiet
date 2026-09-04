import FilterCore
import Foundation
import Observation

/// Home's view model: the App Group settings and counters, as observable state.
@MainActor
@Observable
final class FilterSettings {
    var sensitivity: Config.Sensitivity {
        didSet { AppGroup.setSensitivity(sensitivity) }
    }

    var allowsCodesAndAlerts: Bool {
        didSet { AppGroup.setAllowsCodesAndAlerts(allowsCodesAndAlerts) }
    }

    private(set) var stats: AppGroup.Stats

    /// The extension has never run, so the user has probably not enabled us in
    /// Settings yet. There is no API to ask iOS directly.
    var isProbablyEnabled: Bool {
        stats.lastRun != nil
    }

    init() {
        let config = AppGroup.config()
        sensitivity = config.sensitivity
        allowsCodesAndAlerts = config.allowsCodesAndAlerts
        stats = AppGroup.stats()
    }

    /// The extension writes from its own process, so re-read whenever the app
    /// comes back to the foreground.
    func refresh() {
        stats = AppGroup.stats()
        let config = AppGroup.config()
        if config.sensitivity != sensitivity {
            sensitivity = config.sensitivity
        }
        if config.allowsCodesAndAlerts != allowsCodesAndAlerts {
            allowsCodesAndAlerts = config.allowsCodesAndAlerts
        }
    }

    /// The config the Test Lab should classify with.
    var currentConfig: Config {
        Config(sensitivity: sensitivity, allowsCodesAndAlerts: allowsCodesAndAlerts)
    }
}
