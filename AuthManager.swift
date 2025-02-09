//
//  AuthManager.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import Firebase
import FirebaseAuth

@MainActor
@preconcurrency
final class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: User?
    
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isSignedIn = user != nil
                self?.currentUser = user
            }
        }
    }
    
    deinit {
        if let listener = stateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = result.user
        isSignedIn = true
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUser = result.user
        isSignedIn = true
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isSignedIn = false
    }
}

