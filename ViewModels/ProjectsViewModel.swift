//
//  ProjectsViewModel.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//


import Foundation
import Firebase
import FirebaseFirestore

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadProjects() {
        isLoading = true
        
        Task {
            do {
                let snapshot = try await db.collection("projects")
                    .order(by: "name")
                    .getDocuments()
                
                let loadedProjects = snapshot.documents.compactMap { doc -> Project? in
                    do {
                        return try doc.data(as: Project.self)
                    } catch {
                        print("Error decoding project: \(error)")
                        return nil
                    }
                }
                
                if loadedProjects.isEmpty {
                    projects = Project.defaultProjects
                    try await saveProjects()
                } else {
                    projects = loadedProjects
                }
            } catch {
                errorMessage = "Failed to load projects: \(error.localizedDescription)"
                projects = Project.defaultProjects
            }
            
            isLoading = false
        }
    }
    
    func addProject(name: String) {
        Task {
            do {
                // Проверка на уникальность имени
                guard !projects.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
                    errorMessage = "Project with this name already exists"
                    return
                }
                
                let newProject = Project(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                try await saveProject(newProject)
                projects.append(newProject)
                projects.sort { $0.name < $1.name }
            } catch {
                errorMessage = "Failed to add project: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        Task {
            do {
                // Удаляем все подколлекции
                try await deleteProjectContents(project)
                // Удаляем сам проект
                try await db.collection("projects").document(project.id).delete()
                
                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                    projects.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to delete project: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteProjectContents(_ project: Project) async throws {
        // Удаление папок
        let foldersSnapshot = try await db.collection("projects")
            .document(project.id)
            .collection("folders")
            .getDocuments()
        
        for folder in foldersSnapshot.documents {
            // Удаление подпапок
            let subfoldersSnapshot = try await folder.reference
                .collection("subfolders")
                .getDocuments()
            
            for subfolder in subfoldersSnapshot.documents {
                try await subfolder.reference.delete()
            }
            
            // Удаление фотографий
            let photosSnapshot = try await folder.reference
                .collection("photos")
                .getDocuments()
            
            for photo in photosSnapshot.documents {
                try await photo.reference.delete()
            }
            
            try await folder.reference.delete()
        }
    }
    
    private func saveProject(_ project: Project) async throws {
        let projectData: [String: Any] = [
            "id": project.id,
            "name": project.name,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("projects")
            .document(project.id)
            .setData(projectData)
    }
    
    private func saveProjects() async throws {
        for project in projects {
            try await saveProject(project)
        }
    }
}

