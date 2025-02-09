//
//  ContentView.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

// В функции deleteProjects:
import SwiftUI
import Firebase
import Foundation

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var projectsViewModel = ProjectsViewModel()
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projectsViewModel.projects) { project in
                    NavigationLink(destination: ProjectView(projectName: project.name)) {
                        HStack {
                            Text(project.name)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .opacity(0.7)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await deleteProjects(at: indexSet)
                    }
                }
            }
            .navigationTitle("PROPS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try authManager.signOut()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        } label: {
                            Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("Новый проект", isPresented: $showingAddProject) {
            TextField("Название проекта", text: $newProjectName)
            Button("Отмена", role: .cancel) {
                newProjectName = ""
            }
            Button("Создать") {
                if !newProjectName.isEmpty {
                    Task {
                        await addProject()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadProjects()
        }
    }
    
    private func loadProjects() async {
        do {
            try await projectsViewModel.loadProjects()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func addProject() async {
        do {
            try await projectsViewModel.addProject(name: newProjectName)
            newProjectName = ""
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func deleteProjects(at indexSet: IndexSet) async {
        do {
            for index in indexSet {
                let project = projectsViewModel.projects[index]
                try await projectsViewModel.deleteProject(project)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
