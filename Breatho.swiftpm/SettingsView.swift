import SwiftUI

struct SettingsView: View {
    @Binding var selectedPattern: BreathingPattern
    @State private var showPatternPicker = false
    @State private var hapticFeedback = true
    @State private var soundEffects = true
    @State private var sessionDuration = 5
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Breathing Pattern")) {
                    Button(action: { showPatternPicker = true }) {
                        HStack {
                            Text("Current Pattern")
                            Spacer()
                            Text(selectedPattern.name)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    Toggle("Sound Effects", isOn: $soundEffects)
                    
                    Stepper("Session Duration: \(sessionDuration) minutes", value: $sessionDuration, in: 1...30)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPatternPicker) {
                PatternPickerView(selectedPattern: $selectedPattern)
            }
        }
    }
}

struct PatternPickerView: View {
    @Binding var selectedPattern: BreathingPattern
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(BreathingPattern.patterns) { pattern in
                Button(action: {
                    selectedPattern = pattern
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pattern.name)
                                .font(.headline)
                            Text(pattern.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if pattern.id == selectedPattern.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Pattern")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    SettingsView(selectedPattern: .constant(BreathingPattern.patterns[0]))
} 