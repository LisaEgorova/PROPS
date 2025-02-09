import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let projectName: String
    
    init(projectName: String) {
        self.projectName = projectName
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadFolders()
        await loadPhotos()
    }
    
    private func loadFolders() async {
        do {
            let snapshot = try await db.collection("projects")
                .document(projectName)
                .collection("folders")
                .order(by: "name")
                .getDocuments()
            
            folders = snapshot.documents.compactMap { document -> Folder? in
                do {
                    return try document.data(as: Folder.self)
                } catch {
                    print("Error decoding folder: \(error)")
                    return nil
                }
            }
        } catch {
            errorMessage = "Error loading folders: \(error.localizedDescription)"
        }
    }
    
    private func loadPhotos() async {
        do {
            let snapshot = try await db.collection("projects")
                .document(projectName)
                .collection("photos")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            photos = snapshot.documents.compactMap { document in
                let data = document.data()
                return Photo(
                    id: document.documentID,
                    url: data["url"] as? String ?? "",
                    uploadedBy: data["uploadedBy"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        } catch {
            errorMessage = "Error loading photos: \(error.localizedDescription)"
        }
    }
    
    func uploadPhoto(_ image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Failed to process image"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Генерируем уникальное имя файла с временной меткой
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "\(timestamp)_\(UUID().uuidString)"
            
            let storageRef = storage.reference()
                .child("projects")
                .child(projectName)
                .child("photos")
                .child("\(filename).jpg")
            
            _ = try await storageRef.putDataAsync(imageData, metadata: nil)
            let downloadURL = try await storageRef.downloadURL()
            
            let photoData: [String: Any] = [
                "url": downloadURL.absoluteString,
                "uploadedBy": Auth.auth().currentUser?.email ?? "",
                "timestamp": FieldValue.serverTimestamp(),
                "filename": filename
            ]
            
            try await db.collection("projects")
                .document(projectName)
                .collection("photos")
                .addDocument(data: photoData)
            
            await loadPhotos()
        } catch {
            errorMessage = "Error uploading photo: \(error.localizedDescription)"
        }
    }
    
    func addFolder(name: String) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Folder name cannot be empty"
            return
        }
        
        guard !folders.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            errorMessage = "Folder with this name already exists"
            return
        }
        
        do {
            let newFolder = Folder(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            try await saveFolder(newFolder)
            folders.append(newFolder)
            folders.sort { $0.name < $1.name }
        } catch {
            errorMessage = "Error adding folder: \(error.localizedDescription)"
        }
    }
    
    private func saveFolder(_ folder: Folder) async throws {
        let data: [String: Any] = [
            "id": folder.id,
            "name": folder.name,
            "subfolders": [],
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("projects")
            .document(projectName)
            .collection("folders")
            .document(folder.id)
            .setData(data)
    }
    
    func deletePhoto(_ photo: Photo) async {
        do {
            // Удаляем файл из Storage
            if let filename = photo.url.components(separatedBy: "/").last {
                let storageRef = storage.reference()
                    .child("projects")
                    .child(projectName)
                    .child("photos")
                    .child(filename)
                try await storageRef.delete()
            }
            
            // Удаляем документ из Firestore
            try await db.collection("projects")
                .document(projectName)
                .collection("photos")
                .document(photo.id)
                .delete()
            
            // Обновляем локальный массив
            if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                photos.remove(at: index)
            }
        } catch {
            errorMessage = "Error deleting photo: \(error.localizedDescription)"
        }
    }
}
