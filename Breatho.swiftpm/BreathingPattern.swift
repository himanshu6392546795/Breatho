import Foundation
import Combine

struct BreathingPattern: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let inhaleDuration: TimeInterval
    let holdDuration: TimeInterval
    let exhaleDuration: TimeInterval
    let restDuration: TimeInterval
    let color: String
    
    static let patterns: [BreathingPattern] = [
        BreathingPattern(
            name: "4-7-8 Breathing",
            description: "A calming technique that helps reduce anxiety and promote sleep",
            inhaleDuration: 4,
            holdDuration: 7,
            exhaleDuration: 8,
            restDuration: 0,
            color: "blue"
        ),
        BreathingPattern(
            name: "Box Breathing",
            description: "A simple technique to improve focus and reduce stress",
            inhaleDuration: 4,
            holdDuration: 4,
            exhaleDuration: 4,
            restDuration: 4,
            color: "green"
        ),
        BreathingPattern(
            name: "Equal Breathing",
            description: "Balanced breathing to calm the mind and body",
            inhaleDuration: 4,
            holdDuration: 0,
            exhaleDuration: 4,
            restDuration: 0,
            color: "purple"
        )
    ]
}

@MainActor
class BreathingSession: ObservableObject {
    @Published var currentPattern: BreathingPattern
    @Published var sessionDuration: TimeInterval = 0
    @Published var isActive = false
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(pattern: BreathingPattern = BreathingPattern.patterns[0]) {
        self.currentPattern = pattern
    }
    
    func start() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                self.sessionDuration += 1
            }
        }
    }
    
    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        sessionDuration = 0
    }
} 