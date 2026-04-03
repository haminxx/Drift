//
//  BrickModeSettingsView.swift
//  Drift
//
//  Screen Time auth, apps to block vs essentials (always allowed), break + warning durations.
//  Family Controls capability required. See docs/ENTITLEMENTS.md.
//

import SwiftUI
import FamilyControls

struct BrickModeSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var blockedSelection = FamilyActivitySelection()
    @State private var essentialSelection = FamilyActivitySelection()
    @State private var showBlockedPicker = false
    @State private var showEssentialPicker = false
    @State private var authMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Break length and warning timers are on the Lock tab. Here, authorize Screen Time and choose which apps to block or always allow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Screen Time") {
                    Button("Request Screen Time access") {
                        ShieldManager.shared.requestAuthorization { result in
                            switch result {
                            case .success:
                                authMessage = "Authorized. Pick blocked and essential apps below."
                            case .failure(let e):
                                authMessage = e.localizedDescription
                            }
                        }
                    }
                    if !authMessage.isEmpty {
                        Text(authMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Apps to block in brick mode") {
                    Button("Choose distracting apps") {
                        showBlockedPicker = true
                    }
                    Text("\(blockedSelection.applicationTokens.count) staged · saved: \(ShieldManager.shared.blockedApplicationTokens.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Always allowed (stay open)") {
                    Text("Pick apps that stay usable even when the blocked list would cover them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Choose essential apps") {
                        showEssentialPicker = true
                    }
                    Text("\(essentialSelection.applicationTokens.count) staged · saved: \(ShieldManager.shared.essentialApplicationTokens.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Save selections") {
                        ShieldManager.shared.updateBlockedTokens(from: blockedSelection)
                        ShieldManager.shared.updateEssentialTokens(from: essentialSelection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Apps & Screen Time")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showBlockedPicker) {
                NavigationStack {
                    FamilyActivityPicker(selection: $blockedSelection)
                        .navigationTitle("Block in brick mode")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showBlockedPicker = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showEssentialPicker) {
                NavigationStack {
                    FamilyActivityPicker(selection: $essentialSelection)
                        .navigationTitle("Always allowed")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showEssentialPicker = false }
                            }
                        }
                }
            }
        }
    }
}
