//
//  SettingsView.swift
//  HostingApp
//
//  Created by Alex Baratti on 8/23/26.
//  Copyright © 2026 Apple. All rights reserved.
//

import SeizosKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                #if os(iOS)
                    Section {
                        NavigationLink(
                            destination: AppIconPickerView(
                                options: [
                                    AppIconOption(
                                        id: nil,
                                        displayName: "Default",
                                        preview: Image("AppIconImage")
                                    ),
                                    AppIconOption(
                                        id: "AppIcon-Pi",
                                        displayName: "Pi",
                                        description: "3.1415926535897...",
                                        preview: Image("AppIconImage-Pi")
                                    ),
                                    AppIconOption(
                                        id: "AppIcon-BajaSunset",
                                        displayName: "Baja Sunset",
                                        preview: Image("AppIconImage-BajaSunset")
                                    ),
                                ]
                            )
                            .navigationTitle("App Icon")
                        ) {
                            Label("App Icon", systemImage: "app")
                        }
                    }
                #endif

                Section {
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                    Link(
                        destination: URL(
                            string:
                                "https://alexsmbaratti.com/happykey/privacy-policy/"
                        )!
                    ) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
