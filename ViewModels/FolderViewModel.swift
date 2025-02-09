//
//  FolderViewModel.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@MainActor
class FolderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var subfolders: [Folder] = []
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var showingAddSubfolder = false
    @Published var showingImagePicker = false
    @Published var newSubfolderName = ""
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let projectName: String
    private let folderName: String?
    
    // MARK: - Initialization
    init(projectName: String, folderName: String?) {
        self.projectName = projectName
        self.folderName = folderName
    }
    
    // MARK: - Public Methods
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadSubfolders()
        await loadPhotos()
    }
    
    func addSubfolder(name: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Название папки не может быть пустым"
            return
        }
        
        guard !subfolders.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            errorMessage = "Папка с таким названием уже существует"
            return
        }
        
        do {
            let newFolder = Folder(name: trimmedName)
            try await saveSubfolder(newFolder)
            subfolders.append(newFolder)
            subfolders.sort { $0.name < $1.name }
        } catch {
            errorMessage = "Ошибка при создании папки: \(error.localizedDescription)"
        }
    }
    
    func uploadPhoto(_ image: UIImage) async {
        guard let folderName = folderName,
              let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let filename = UUID().uuidString + ".jpg"
            let storageRef = storage.reference()
                .child("projects")
                .child(projectName)
                .child("folders")
                .child(folderName)
                .child("photos")
                .child(filename)
            
            _ = try await storageRef.putDataAsync(imageData)
            let downloadURL = try await storageRef.downloadURL()
            
            let photo = Photo(
                url: downloadURL.absoluteString,
                uploadedBy: Auth.auth().currentUser?.email ?? ""
            )
            
            try await db.collection("projects")
                .document(projectName)
                .collection("folders")
                .document(folderName)
                .collection("photos")
                .document(photo.id)
                .setData([
                    "id": photo.id,
                    "url": photo.url,
                    "uploadedBy": photo.uploadedBy,
                    "timestamp": FieldValue.serverTimestamp()
                ])
            
            await loadPhotos()
        } catch {
            errorMessage = "Ошибка при загрузке фото: \(error.localizedDescription)"
        }
    }
    
    func deletePhoto(_ photo: Photo) async {
        guard let folderName = folderName else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Удаляем файл из Storage
            let storageRef = storage.reference()
                .child("projects")
                .child(projectName)
                .child("folders")
                .child(folderName)
                .child("photos")
                .child("\(photo.id).jpg")
            
            try await storageRef.delete()
            
            // Удаляем документ из Firestore
            try await db.collection("projects")
                .document(projectName)
                .collection("folders")
                .document(folderName)
                .collection("photos")
                .document(photo.id)
                .delete()
            
            // Обновляем локальный массив
            photos.removeAll { $0.id == photo.id }
        } catch {
            errorMessage = "Ошибка при удалении фото: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    private func loadSubfolders() async {
        do {
            let folderRef = getFolderReference()
            let snapshot = try await folderRef
                .order(by: "name")
                .getDocuments()
            
            subfolders = snapshot.documents.compactMap { document -> Folder? in
                try? document.data(as: Folder.self)
            }
            
            if subfolders.isEmpty && folderName == nil {
                await createDefaultFolders()
            }
        } catch {
            errorMessage = "Ошибка при загрузке папок: \(error.localizedDescription)"
        }
    }
    
    private func loadPhotos() async {
        guard let folderName = folderName else { return }
        
        do {
            let snapshot = try await db.collection("projects")
                .document(projectName)
                .collection("folders")
                .document(folderName)
                .collection("photos")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            photos = snapshot.documents.compactMap { document in
                let data = document.data()
                return Photo(
                    id: document.documentID,
                    url: data["url"] as? String ?? "",
                    uploadedBy: data["uploadedBy"] as? String ?? ""
                )
            }
        } catch {
            errorMessage = "Ошибка при загрузке фотографий: \(error.localizedDescription)"
        }
    }
    
    private func saveSubfolder(_ folder: Folder) async throws {
        let folderRef = getFolderReference().document(folder.id)
        try await folderRef.setData([
            "id": folder.id,
            "name": folder.name,
            "timestamp": FieldValue.serverTimestamp()
        ])
    }
    
    private func getFolderReference() -> CollectionReference {
        if let folderName = folderName {
            return db.collection("projects")
                .document(projectName)
                .collection("folders")
                .document(folderName)
                .collection("subfolders")
        } else {
            return db.collection("projects")
                .document(projectName)
                .collection("folders")
        }
    }
    
    private func createDefaultFolders() async {
        let defaultFolders = [
            Folder(name: "Локации"),
            Folder(name: "Персонажи"),
            Folder(name: "Съемки"),
            Folder(name: "Полиграфия"),
            Folder(name: "Стыки")
        ]
        
        for folder in defaultFolders {
            do {
                try await saveSubfolder(folder)
                subfolders.append(folder)
            } catch {
                errorMessage = "Ошибка при создании папки по умолчанию: \(error.localizedDescription)"
            }
        }
        
        subfolders.sort { $0.name < $1.name }
    }
}
