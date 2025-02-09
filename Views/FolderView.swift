//
//  FolderView.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct FolderView: View {
    let projectName: String
    let folderName: String
    @StateObject private var viewModel = FolderViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(viewModel.photos) { photo in
                    PhotoView(photo: photo)
                }
            }
            .padding()
        }
        .navigationTitle(folderName)
        .toolbar {
            Menu {
                Button(action: { showingImagePicker = true }) {
                    Label("Галерея", systemImage: "photo.on.rectangle")
                }
                Button(action: { showingCamera = true }) {
                    Label("Камера", systemImage: "camera")
                }
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                Task {
                    await viewModel.uploadPhoto(image)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                Task {
                    await viewModel.uploadPhoto(image, projectName: projectName, folderName: folderName)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPhotos(projectName: projectName, folderName: folderName)
            }
        }
    }
}
