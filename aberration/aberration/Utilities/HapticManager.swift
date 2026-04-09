import UIKit
import CoreHaptics

/// Core Haptics manager for Stillhue.
///
/// Design philosophy: zen/calm game → haptics should feel like gentle taps,
/// soft thuds, and warm pulses. Never jarring. Think: the feeling of
/// pressing a well-made piano key, not a video game button.
///
/// Falls back to UIKit feedback generators on devices without Core Haptics.
enum HapticManager {

    // MARK: - Settings

    static var isEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "chr_haptics_disabled") }
        set { UserDefaults.standard.set(!newValue, forKey: "chr_haptics_disabled") }
    }

    /// Haptic intensity (0.0 – 1.0), stepped in 0.1 by the UI.
    /// Multiplied into every haptic event intensity.
    static var intensity: Float {
        get {
            let val = UserDefaults.standard.float(forKey: "chr_haptic_intensity")
            return val == 0 && !UserDefaults.standard.bool(forKey: "chr_haptic_intensity_set") ? 1.0 : val
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "chr_haptic_intensity")
            UserDefaults.standard.set(true, forKey: "chr_haptic_intensity_set")
        }
    }

    // MARK: - Engine

    private static var engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            // Restart engine silently if it stops (e.g., app backgrounded)
            engine.resetHandler = {
                try? engine.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            return engine
        } catch {
            return nil
        }
    }()

    private static var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Public API (unchanged signatures)

    /// Tile select — soft, precise tap. Like touching a glass marble.
    static func tilePlaced() {
        guard isEnabled else { return }
        if let engine {
            playPattern(on: engine, events: [
                // Single gentle transient — light and crisp
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ],
                    relativeTime: 0
                )
            ])
        } else {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred(intensity: 0.5)
        }
    }

    /// Blend — two colors becoming one. A warm "thump" with a soft tail.
    /// Like two drops of water merging.
    static func blend() {
        guard isEnabled else { return }
        if let engine {
            playPattern(on: engine, events: [
                // Initial soft thud — the moment of contact
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ],
                    relativeTime: 0
                ),
                // Gentle continuous bloom — the colors spreading into each other
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.08)
                    ],
                    relativeTime: 0.04,
                    duration: 0.12
                )
            ])
        } else {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred(intensity: 0.6)
        }
    }

    /// Round complete — satisfying resolution. Rising warmth, like a deep breath out.
    static func lineClear() {
        guard isEnabled else { return }
        if let engine {
            playPattern(on: engine, events: [
                // Firm but round initial tap — "yes!"
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0
                ),
                // Warm swell — building satisfaction
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.06,
                    duration: 0.18
                ),
                // Gentle fade-out tap — resolution
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.28
                )
            ])
        } else {
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.impactOccurred(intensity: 0.7)
        }
    }

    /// Celebration — playful ascending pulses, like bubbles rising.
    static func cascade() {
        guard isEnabled else { return }
        if let engine {
            // Three gentle ascending taps — playful, not aggressive
            var events: [CHHapticEvent] = []
            let intensities: [Float] = [0.3, 0.4, 0.5]
            let sharpnesses: [Float] = [0.15, 0.2, 0.25]
            for i in 0..<3 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensities[i]),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnesses[i])
                    ],
                    relativeTime: Double(i) * 0.09
                ))
            }
            playPattern(on: engine, events: events)
        } else {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        }
    }

    /// Game over — gentle, sympathetic. Not punishing.
    /// A soft sigh, not a slap. The player already feels bad enough.
    static func gameOver() {
        guard isEnabled else { return }
        if let engine {
            playPattern(on: engine, events: [
                // Soft descending thud — like setting something down
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)
                    ],
                    relativeTime: 0
                ),
                // Very gentle continuous fade — empathy, not punishment
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                    ],
                    relativeTime: 0.08,
                    duration: 0.2
                )
            ])
        } else {
            // UIKit fallback: use warning instead of error — softer
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.warning)
        }
    }

    // MARK: - Private

    private static func playPattern(on engine: CHHapticEngine, events: [CHHapticEvent]) {
        do {
            // Scale every event's intensity by the user's intensity preference
            let scaled = events.map { event -> CHHapticEvent in
                let params = event.eventParameters.map { param -> CHHapticEventParameter in
                    if param.parameterID == .hapticIntensity {
                        return CHHapticEventParameter(
                            parameterID: .hapticIntensity,
                            value: param.value * intensity
                        )
                    }
                    return CHHapticEventParameter(
                        parameterID: param.parameterID,
                        value: param.value
                    )
                }
                return CHHapticEvent(
                    eventType: event.type,
                    parameters: params,
                    relativeTime: event.relativeTime,
                    duration: event.duration
                )
            }
            let pattern = try CHHapticPattern(events: scaled, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silent failure — haptics are non-critical
        }
    }
}
