//
//  AboutView.swift
//  HostingApp
//
//  Created by Alex Baratti on 4/16/26.
//  Copyright © 2026 Apple. All rights reserved.
//

import SeizosKit
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    let version =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    let credits = [
        IndividualCredit(
            name: "Alex Baratti",
            role: "Developer"
        ),
        IndividualCredit(
            name: "Ryan Nemiroff",
            role: "Developer"
        ),
        IndividualCredit(
            name: "Jeff Simon",
            role: "Math Teacher"
        ),
    ]
    let dependencyCredits = [
        AttributionCredit(
            name: "TastyImitationKeyboard",
            description: """
            Provides framework for keyboard.
            
            Copyright (c) 2014, Alexei Baboulevitch ("Archagon")
            All rights reserved.

            Redistribution and use in source and binary forms, with or without
            modification, are permitted provided that the following conditions are met:
                * Redistributions of source code must retain the above copyright
                  notice, this list of conditions and the following disclaimer.
                * Redistributions in binary form must reproduce the above copyright
                  notice, this list of conditions and the following disclaimer in the
                  documentation and/or other materials provided with the distribution.
                * Neither the name of the organization nor the
                  names of its contributors may be used to endorse or promote products
                  derived from this software without specific prior written permission.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
            ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
            WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
            DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
            DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
            (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
            LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
            ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
            (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
            SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
            """,
            url: URL(
                string: "https://github.com/archagon/tasty-imitation-keyboard"
            )
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                AppInfoSection(
                    appName: "HappyKey",
                    appVersion: version,
                    buildNumber: build,
                    appIcon: Image("AppIconImage")
                )

                IndividualCreditsSection(
                    credits: credits
                )

                AttributionCreditsSection(
                    credits: dependencyCredits
                )
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarTrailing,
                    content: {
                        Button(
                            action: {
                                dismiss()
                            },
                            label: {
                                Text("Done")
                            }
                        )
                    }
                )
            }
        }
    }
}

#Preview {
    AboutView()
}
