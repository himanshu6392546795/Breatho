import SwiftUI

@MainActor
class BreathingAnimationManager: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var opacity: Double = 0.6
    @Published var currentPhase: String = "Ready"
    @Published var timeRemaining: TimeInterval = 0
    @Published var phaseProgress: Double = 0.0
    
    private var animationTimer: Timer?
    private var phaseTimer: Timer?
    private var phaseIndex = 0
    private var currentPattern: BreathingPattern?
    private let soundManager = SoundManager.shared
    
    func startAnimation(pattern: BreathingPattern) {
        currentPattern = pattern
        timeRemaining = 0
        phaseIndex = 0
        startPhase()
        soundManager.playBreathingSound()
    }
    
    private func startPhase() {
        guard let pattern = currentPattern else { return }
        
        let duration: TimeInterval
        switch phaseIndex {
        case 0: // Inhale
            currentPhase = "Breathe In"
            duration = pattern.inhaleDuration
        case 1: // Hold
            currentPhase = "Hold"
            duration = pattern.holdDuration
        case 2: // Exhale
            currentPhase = "Breathe Out"
            duration = pattern.exhaleDuration
        case 3: // Rest
            currentPhase = "Rest"
            duration = pattern.restDuration
        default:
            return
        }
        
        // Play haptic feedback for phase change
        soundManager.playPhaseChangeHaptic()
        
        // Start phase timer
        phaseProgress = 0
        phaseTimer?.invalidate()
        
        // Create a non-isolated function to handle timer updates
        let updateProgress: @Sendable () -> Void = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.phaseProgress += 0.1 / duration
                self.timeRemaining += 0.1
                if self.phaseProgress >= 1.0 {
                    self.phaseTimer?.invalidate()
                    self.nextPhase()
                }
            }
        }
        
        // Schedule the timer with the non-isolated update function
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateProgress()
        }
        
        // Update animation based on phase
        withAnimation(.easeInOut(duration: duration)) {
            switch phaseIndex {
            case 0: // Inhale
                scale = 1.5
                opacity = 0.8
            case 1: // Hold
                break
            case 2: // Exhale
                scale = 1.0
                opacity = 0.6
            case 3: // Rest
                break
            default:
                break
            }
        }
    }
    
    private func nextPhase() {
        phaseIndex = (phaseIndex + 1) % 4
        startPhase()
    }
    
    func stopAnimation() {
        animationTimer?.invalidate()
        phaseTimer?.invalidate()
        animationTimer = nil
        phaseTimer = nil
        soundManager.stopBreathingSound()
        soundManager.playCompletionHaptic()
        reset()
    }
    
    private func reset() {
        scale = 1.0
        opacity = 0.6
        currentPhase = "Ready"
        timeRemaining = 0
        phaseProgress = 0
        phaseIndex = 0
    }
}

struct ContentView: View {
    @StateObject private var breathingSession = BreathingSession()
    @StateObject private var animationManager = BreathingAnimationManager()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "2C3E50").opacity(0.8),
                    Color(hex: "3498DB").opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Breatho")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 220, height: 220)
                        .blur(radius: 10)
                    
                    // Main circle
                    Circle()
                        .fill(Color.white.opacity(animationManager.opacity))
                        .frame(width: 200, height: 200)
                        .scaleEffect(animationManager.scale)
                    
                    // Phase indicator
                    Circle()
                        .trim(from: 0, to: animationManager.phaseProgress)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 10) {
                        Text(animationManager.currentPhase)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(formatTime(animationManager.timeRemaining))
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Pattern info
                VStack(spacing: 12) {
                    Text(breathingSession.currentPattern.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(breathingSession.currentPattern.description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                // Control button
                Button(action: {
                    if breathingSession.isActive {
                        breathingSession.stop()
                        animationManager.stopAnimation()
                    } else {
                        breathingSession.start()
                        animationManager.startAnimation(pattern: breathingSession.currentPattern)
                    }
                }) {
                    Text(breathingSession.isActive ? "Stop" : "Start")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(breathingSession.isActive ? Color.red : Color.green)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(selectedPattern: $breathingSession.currentPattern)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
