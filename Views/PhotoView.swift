//
//  PhotoView.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import SwiftUI
import SDWebImageSwiftUI
import Photos

struct PhotoView: View {
    let photo: Photo
    @State private var showingFullScreen = false
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            WebImage(url: URL(string: photo.url))
                .onSuccess { _, _, _ in
                    isLoading = false
                }
                .onFailure { _, error in
                    errorMessage = error.localizedDescription
                    showError = true
                }
                .resizable()
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)
            
            if isLoading {
                ProgressView()
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .onTapGesture {
            showingFullScreen = true
        }
        .sheet(isPresented: $showingFullScreen) {
            FullScreenPhotoView(photo: photo)
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct FullScreenPhotoView: View {
    let photo: Photo
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    WebImage(url: URL(string: photo.url))
                        .onSuccess { _, _, _ in
                            isLoading = false
                        }
                        .onFailure { _, error in
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                        .resizable()
                        .placeholder {
                            Color.gray.opacity(0.3)
                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1 ? 1 : 2
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveImage) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Успешно", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Фото сохранено в галерею")
        }
    }
    
    private func saveImage() {
        Task {
            do {
                let authorized = try await checkPhotoLibraryPermission()
                guard authorized else {
                    throw NSError(domain: "", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Нет доступа к галерее. Пожалуйста, предоставьте разрешение в настройках."
                    ])
                }
                
                if let url = URL(string: photo.url),
                   let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    showingSaveSuccess = true
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Не удалось сохранить изображение"
                    ])
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func checkPhotoLibraryPermission() async throws -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

