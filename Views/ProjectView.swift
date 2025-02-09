//
//  ProjectView.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import SwiftUI
import Firebase

struct ProjectView: View {
    // MARK: - Properties
    let projectName: String
    @StateObject private var viewModel: ProjectViewModel
    
    // MARK: - State Properties
    @State private var showingAddFolder = false
    @State private var showingImagePicker = false
    @State private var newFolderName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedFolder: Folder?
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(projectName: String) {
        self.projectName = projectName
        _viewModel = StateObject(wrappedValue: ProjectViewModel(projectName: projectName))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            List {
                // Folders Section
                if !viewModel.folders.isEmpty {
                    Section {
                        ForEach(viewModel.folders) { folder in
                            folderRow(folder)
                        }
                    } header: {
                        Text("Папки")
                    }
                }
                
                // Photos Section
                if !viewModel.photos.isEmpty {
                    Section {
                        photosGrid
                    } header: {
                        Text("Фотографии")
                    }
                }
                
                // Empty State
                if viewModel.folders.isEmpty && viewModel.photos.isEmpty {
                    emptyStateView
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
            .navigationTitle(projectName)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .alert("Новая папка", isPresented: $showingAddFolder) {
            folderAlert
        }
        .alert("Удаление папки", isPresented: $showingDeleteConfirmation) {
            deleteAlert
        } message: {
            Text("Вы уверены, что хотите удалить папку '\(selectedFolder?.name ?? "")'? Это действие нельзя отменить.")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary,
                       errorMessage: $errorMessage) { image in
                Task {
                    await viewModel.uploadPhoto(image)
                }
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - View Components
    private var photosGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            ForEach(viewModel.photos) { photo in
                PhotoView(photo: photo)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deletePhoto(photo)
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        Section {
            Text("Проект пуст")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
    }
    
    private var addButton: some View {
        Menu {
            Button {
                newFolderName = ""
                showingAddFolder = true
            } label: {
                Label("Добавить папку", systemImage: "folder.badge.plus")
            }
            
            Button {
                showingImagePicker = true
            } label: {
                Label("Добавить фото", systemImage: "photo.badge.plus")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
        }
    }
    
    private var folderAlert: some View {
        Group {
            TextField("Название папки", text: $newFolderName)
                .textInputAutocapitalization(.words)
            Button("Отмена", role: .cancel) { }
            Button("Создать") {
                guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await addFolder()
                }
            }
        }
    }
    
    private var deleteAlert: some View {
        Group {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                guard let folder = selectedFolder else { return }
                Task {
                    await deleteFolder(folder)
                }
            }
        }
    }
    
    private func folderRow(_ folder: Folder) -> some View {
        NavigationLink(destination: FolderView(projectName: projectName, folderName: folder.name)) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                    .opacity(0.7)
                Text(folder.name)
                    .font(.headline)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                selectedFolder = folder
                showingDeleteConfirmation = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                selectedFolder = folder
                showingDeleteConfirmation = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func addFolder() async {
        do {
            try await viewModel.addFolder(name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines))
            newFolderName = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteFolder(_ folder: Folder) async {
        do {
            try await $viewModel.deleteFolder(folder)
            selectedFolder = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ProjectView(projectName: "Test Project")
    }
}
