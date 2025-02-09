//
//  Folder.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//


import Foundation

struct Folder: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let name: String
    var createdAt: Date?
    var subfolders: [Folder]
    var photos: [Photo]
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         name: String,
         createdAt: Date? = Date(),
         subfolders: [Folder] = [],
         photos: [Photo] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.subfolders = subfolders
        self.photos = photos
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case subfolders
        case photos
    }
}

// MARK: - Equatable
extension Folder: Equatable {
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Folder: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Default Folders
extension Folder {
    static let defaultFolders = [
        Folder(name: "Локации"),
        Folder(name: "Персонажи"),
        Folder(name: "Съемки"),
        Folder(name: "Полиграфия"),
        Folder(name: "Стыки")
    ]
}

// MARK: - Helper Methods
extension Folder {
    /// Проверяет, содержит ли папка подпапку с указанным именем
    func containsSubfolder(named name: String) -> Bool {
        subfolders.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Возвращает общее количество фотографий в папке и всех подпапках
    var totalPhotosCount: Int {
        photos.count + subfolders.reduce(0) { $0 + $1.totalPhotosCount }
    }
    
    /// Возвращает дату создания в отформатированном виде
    var formattedCreatedAt: String {
        guard let date = createdAt else { return "Нет даты" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

// MARK: - Firebase Helpers
extension Folder {
    /// Конвертирует папку в словарь для Firebase
    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "createdAt": createdAt as Any,
            "subfolders": subfolders.map { $0.asDictionary },
            "photos": photos.map { $0.asDictionary }
        ]
    }
    
    /// Создает папку из словаря Firebase
    static func fromDictionary(_ dict: [String: Any]) -> Folder? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String
        else { return nil }
        
        let createdAt = dict["createdAt"] as? Date
        let subfoldersData = dict["subfolders"] as? [[String: Any]] ?? []
        let photosData = dict["photos"] as? [[String: Any]] ?? []
        
        let subfolders = subfoldersData.compactMap { Folder.fromDictionary($0) }
        let photos = photosData.compactMap { Photo.fromDictionary($0) }
        
        return Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            subfolders: subfolders,
            photos: photos
        )
    }
}
