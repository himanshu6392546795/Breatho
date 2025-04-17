import Foundation
import AVFoundation
import CoreHaptics

@MainActor
final class SoundManager: ObservableObject, Sendable {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticPatternPlayer?
    private let queue = DispatchQueue(label: "com.breatho.soundmanager", qos: .userInitiated)
    
    private init() {
        setupAudio()
        setupHaptics()
    }
    
    private func setupAudio() {
        Task { @MainActor in
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error)")
            }
        }
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        Task { @MainActor in
            do {
                self.engine = try CHHapticEngine()
                try self.engine?.start()
            } catch {
                print("Failed to start haptic engine: \(error)")
            }
        }
    }
    
    func playBreathingSound() {
        Task { @MainActor in
            guard let url = Bundle.main.url(forResource: "breathing", withExtension: "mp3") else { return }
            
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.numberOfLoops = -1 // Loop indefinitely
                self.player?.play()
            } catch {
                print("Failed to play breathing sound: \(error)")
            }
        }
    }
    
    func stopBreathingSound() {
        Task { @MainActor in
            self.player?.stop()
        }
    }
    
    func playPhaseChangeHaptic() {
        Task { @MainActor in
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            do {
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try self.engine?.makePlayer(with: pattern)
                try player?.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Failed to play haptic: \(error)")
            }
        }
    }
    
    func playCompletionHaptic() {
        Task { @MainActor in
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            do {
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try self.engine?.makePlayer(with: pattern)
                try player?.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Failed to play haptic: \(error)")
            }
        }
    }
} 