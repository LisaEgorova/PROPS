//
//  PROPSApp.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//
import SwiftUI
import Firebase

@main
struct PROPSApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isSignedIn {
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
