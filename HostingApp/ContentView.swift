//
//  ContentView.swift
//  HostingApp
//
//  Created by Alex Baratti on 2/18/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let steps = [
        OnboardingStep(image: Image("HappyKey"), title: "Welcome to HappyKey", description: "Math notation just got simpler! Follow these steps to setup your keyboard."),
        OnboardingStep(image: Image(systemName: "gear"), title: "Enable HappyKey in Settings", description: "Open Settings, select Keyboards, and enable the HappyKey keyboard."),
        OnboardingStep(image: Image(systemName: "globe"), title: "Switch Keyboards", description: "In any text field, just tap on the globe icon to switch to the HappyKey keyboard. Tap the globe icon again to switch back when finished."),
        OnboardingStep(image: Image(systemName: "divide"), title: "Additional Symbols", description: "Some of the keys display additional symbols when tapped and help. Superscripts and subscripts are available for numbers. Traditional multiplication and division symbols are also available."),
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
                .font(.title3)
                .foregroundStyle(index == 0 ? .white : .gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            if index == 1 {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            } else if index == 2 {
                Text("Try typing y=2x+5 in the text field below.")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                KeyboardTestView()
            } else if index == 4 {
                Text("You may now exit the app.")
                    .font(.title3)
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
        .gesture(DragGesture().onEnded { value in
            if value.translation.width < -50 { // Swipe left to next step
                goToNextStep()
            }
        })
        .padding()
    }
    
    @ViewBuilder
    private func nextStepView() -> some View {
        if index < steps.count - 1 {
            OnboardingStepView(step: steps[index + 1], steps: steps, index: index + 1)
        }
    }
    
    private func goToNextStep() {
        // Handle swipe navigation in NavigationStack
    }
}

struct KeyboardTestView: View {
    @State var text = ""
    var body: some View {
        VStack {
            TextField("Test it out here!", text: $text)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ContentView()
}
