import UIKit
import CoreHaptics

enum HapticManager {

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
    }

    // MARK: - Simple haptics

    static func tap()    { guard isEnabled else { return }; impact(.light) }
    static func play()   { guard isEnabled else { return }; impact(.medium) }
    static func win()    { guard isEnabled else { return }; notify(.success) }
    static func lose()   { guard isEnabled else { return }; notify(.error) }

    // MARK: - Special card effects (CoreHaptics)

    /// 2 — reset: heavy rumble that fades out, punctuated by descending sharp hits
    static func playReset() {
        guard isEnabled else { return }
        chPlay([
            // Underlying rumble fading out
            .continuous(time: 0.00, duration: 0.50, intensity: 1.0, sharpness: 0.1,
                        curve: [(0, 1.0), (0.4, 0.5), (1.0, 0.0)]),
            // Sharp transient hits stepping down
            .transient(time: 0.00, intensity: 1.0,  sharpness: 1.0),
            .transient(time: 0.13, intensity: 0.8,  sharpness: 0.7),
            .transient(time: 0.26, intensity: 0.5,  sharpness: 0.4),
            .transient(time: 0.39, intensity: 0.2,  sharpness: 0.1),
        ])
    }

    /// 7 — low mode: rumble that builds up, punctuated by ascending sharp hits (exact reverse)
    static func playLow() {
        guard isEnabled else { return }
        chPlay([
            // Underlying rumble building up
            .continuous(time: 0.00, duration: 0.50, intensity: 1.0, sharpness: 0.1,
                        curve: [(0, 0.0), (0.6, 0.5), (1.0, 1.0)]),
            // Sharp transient hits stepping up
            .transient(time: 0.00, intensity: 0.2,  sharpness: 0.1),
            .transient(time: 0.13, intensity: 0.5,  sharpness: 0.4),
            .transient(time: 0.26, intensity: 0.8,  sharpness: 0.7),
            .transient(time: 0.39, intensity: 1.0,  sharpness: 1.0),
        ])
    }

    /// 10 — burn: sharp crack then a continuous rumble that fades to nothing
    static func playBurn() {
        guard isEnabled else { return }
        chPlay([
            .transient(time: 0.00, intensity: 1.0, sharpness: 1.0),
            .continuous(time: 0.05, duration: 0.45, intensity: 0.6, sharpness: 0.1,
                        curve: [(0, 0.6), (0.3, 0.3), (0.7, 0.1), (1.0, 0.0)]),
        ])
    }

    /// Pick up pile — two heavy double-thumps with a short gap, like an urgent warning
    static func pickupAlert() {
        guard isEnabled else { return }
        chPlay([
            // First double-thump
            .transient(time: 0.00, intensity: 1.0, sharpness: 0.9),
            .transient(time: 0.08, intensity: 1.0, sharpness: 0.9),
            // Brief gap, then second double-thump
            .transient(time: 0.22, intensity: 1.0, sharpness: 0.9),
            .transient(time: 0.30, intensity: 1.0, sharpness: 0.9),
            // Heavy continuous thud underneath both thumps
            .continuous(time: 0.00, duration: 0.38, intensity: 0.8, sharpness: 0.05,
                        curve: [(0, 0.8), (0.5, 0.8), (1.0, 0.0)]),
        ])
    }

    // MARK: - Engine

    private static let engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        let e = try? CHHapticEngine()
        e?.playsHapticsOnly = true
        e?.isAutoShutdownEnabled = false
        try? e?.start()
        e?.resetHandler       = { try? e?.start() }
        e?.stoppedHandler     = { _ in try? e?.start() }
        return e
    }()

    // MARK: - CoreHaptics event types

    private enum CHEvent {
        case transient(time: TimeInterval, intensity: Float, sharpness: Float)
        case continuous(time: TimeInterval, duration: TimeInterval,
                        intensity: Float, sharpness: Float,
                        curve: [(TimeInterval, Float)])
    }

    private static func chPlay(_ events: [CHEvent]) {
        guard let engine else {
            // Fallback on devices without taptic engine
            impact(.heavy); return
        }
        do {
            var chEvents: [CHHapticEvent] = []
            var chParams: [CHHapticParameterCurve] = []

            for event in events {
                switch event {
                case let .transient(time, intensity, sharpness):
                    chEvents.append(CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                        ],
                        relativeTime: time
                    ))

                case let .continuous(time, duration, intensity, sharpness, curve):
                    chEvents.append(CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                        ],
                        relativeTime: time,
                        duration: duration
                    ))
                    if !curve.isEmpty {
                        let keyFrames = curve.map {
                            CHHapticParameterCurve.ControlPoint(relativeTime: $0.0, value: $0.1)
                        }
                        chParams.append(CHHapticParameterCurve(
                            parameterID: .hapticIntensityControl,
                            controlPoints: keyFrames,
                            relativeTime: time
                        ))
                    }
                }
            }

            let pattern = try CHHapticPattern(events: chEvents, parameterCurves: chParams)
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impact(.heavy)
        }
    }

    // MARK: - UIKit primitives

    private static func impact(_ s: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: s); g.prepare(); g.impactOccurred()
    }
    private static func notify(_ t: UINotificationFeedbackGenerator.FeedbackType) {
        let g = UINotificationFeedbackGenerator(); g.prepare(); g.notificationOccurred(t)
    }
}
