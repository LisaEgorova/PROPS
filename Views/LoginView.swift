//
//  LoginView.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    
    private var isValidForm: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6 &&
        email.contains("@")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 25) {
                    // Заголовок
                    Text("PROPS")
                        .font(.system(size: 40, weight: .bold))
                        .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        // Email поле
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(.gray)
                            
                            TextField("example@email.com", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        
                        // Пароль
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showPassword {
                                    TextField("Минимум 6 символов", text: $password)
                                } else {
                                    SecureField("Минимум 6 символов", text: $password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        if isSignUp {
                            Text("Пароль должен содержать минимум 6 символов")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Кнопка входа/регистрации
                    Button(action: handleAuthentication) {
                        ZStack {
                            Text(isSignUp ? "Зарегистрироваться" : "Войти")
                                .fontWeight(.semibold)
                                .opacity(isLoading ? 0 : 1)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidForm ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isValidForm || isLoading)
                    .padding(.horizontal)
                    
                    // Переключатель регистрация/вход
                    Button(action: { withAnimation { isSignUp.toggle() } }) {
                        Text(isSignUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthentication() {
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = localizeError(error)
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func localizeError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        // Локализация стандартных ошибок Firebase
        switch errorMessage {
        case let message where message.contains("email address is badly formatted"):
            return "Неверный формат email адреса"
        case let message where message.contains("password is invalid"):
            return "Неверный пароль"
        case let message where message.contains("no user record"):
            return "Пользователь не найден"
        case let message where message.contains("email address is already"):
            return "Этот email уже используется"
        case let message where message.contains("network error"):
            return "Ошибка сети. Проверьте подключение к интернету"
        default:
            return errorMessage
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}

