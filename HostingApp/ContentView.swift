//
//  ContentView.swift
//  HostingApp
//
//  Created by Alex Baratti on 2/18/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

var exampleGoal = "y=2x+5"

struct ContentView: View {
    let steps = [
        OnboardingStep(image: Image("HappyKey"), title: "Welcome to HappyKey", description: "Math notation just got simpler! Follow these steps to setup your keyboard."),
        OnboardingStep(image: Image(systemName: "gear"), title: "Enable HappyKey in Settings", description: "Open Settings, select Keyboards, and enable the HappyKey keyboard."),
        OnboardingStep(image: Image(systemName: "globe"), title: "Switch Keyboards", description: "In any text field, just tap on the globe icon to switch to the HappyKey keyboard. Tap the globe icon again to switch back when finished."),
        OnboardingStep(image: Image(systemName: "keyboard"), title: "Try It Yourself", description: "Switch keyboards and type \(exampleGoal)"),
        OnboardingStep(image: Image(systemName: "divide"), title: "Additional Symbols", description: "Some of the keys display additional symbols when tapped and held. Superscripts and subscripts are available for numbers. The shift key in the bottom left corner will reveal more symbols."),
        OnboardingStep(image: Image("HappyKey"), title: "You're All Set!", description: "Enjoy using the HappyKey keyboard anywhere you need math notation!")
    ]
    
    var body: some View {
        NavigationStack {
            OnboardingStepView(step: steps[0], steps: steps, index: 0)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("LightBlue"), Color("DarkBlue")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct OnboardingStep: Identifiable {
    let id = UUID()
    let image: Image
    let title: String
    let description: String
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let steps: [OnboardingStep]
    let index: Int
    
    @State var keyboardTestFeedback = ""
    @State var keyboardTestText = ""
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            step.image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(index == 0 ? .white : index == steps.count - 1 ? Color("MainBlue") : .blue)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    if index == steps.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                rotationAngle += 360
                            }
                        }
                    }
                }
            
            Text(step.title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(index == 0 ? .white : .primary)
            
            Text(step.description)
                .font(.body)
                .foregroundStyle(index == 0 ? .white : .gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            if index == 0 {
                if keyboardIsIntalled() {
                    Text("It appears that the HappyKey keyboard is already setup. Use it anywhere by selecting it from the keyboard switcher. This app is just for setup.")
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            } else if index == 1 {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            } else if index == 4 {
                Image("KeyboardPop")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 125)
            } else if index == 3 {
                Text(keyboardTestFeedback)
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                TextField("Test it out here!", text: $keyboardTestText)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .font(.title)
                    .onChange(of: keyboardTestText) { newValue in
                        if newValue == exampleGoal {
                            keyboardTestFeedback = "Well done!"
                        } else {
                            keyboardTestFeedback = ""
                        }
                    }
            } else if index == steps.count - 1 {
                Text("You may now exit the app.")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            if index < steps.count - 1 {
                NavigationLink(
                    destination: nextStepView(),
                    label: {
                        Text(index < steps.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func nextStepView() -> some View {
        if index < steps.count - 1 {
            OnboardingStepView(step: steps[index + 1], steps: steps, index: index + 1)
        }
    }
    
    func keyboardIsIntalled() -> Bool {
        if let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] {
            return keyboards.contains("com.blogspot.mathjoy.MathSymbols.Keyboard")
        }
        return false
    }
}

#Preview {
    ContentView()
}

#if DEBUG
var screenshotConfig1 = OnboardingStep(image: Image(systemName: "questionmark.circle"), title: "Pop Quiz", description: "What is point-slope form?")
var screenshotConfig2 = OnboardingStep(image: Image(systemName: "angle"), title: "Solve", description: "How many degrees are in a right triangle?")

struct AppStoreScreenshotView: View {
    let step: OnboardingStep
    
    @State var keyboardTestText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            step.image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            
            Text(step.title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            
            Text(step.description)
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
 
            TextField("Type Here", text: $keyboardTestText)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .font(.title)
            
            Spacer()
        }
        .padding()
    }
}
#endif
