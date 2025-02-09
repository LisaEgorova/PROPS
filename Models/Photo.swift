//
//  Photo.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import Foundation

struct Photo: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let url: String
    let uploadedBy: String
    let timestamp: Date
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         url: String,
         uploadedBy: String,
         timestamp: Date = Date()) {
        self.id = id
        self.url = url
        self.uploadedBy = uploadedBy
        self.timestamp = timestamp
    }
}

// MARK: - Equatable
extension Photo: Equatable {
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Photo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Firebase Helpers
extension Photo {
    var asDictionary: [String: Any] {
        [
            "id": id,
            "url": url,
            "uploadedBy": uploadedBy,
            "timestamp": timestamp
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Photo? {
        guard
            let id = dict["id"] as? String,
            let url = dict["url"] as? String,
            let uploadedBy = dict["uploadedBy"] as? String,
            let timestamp = dict["timestamp"] as? Date
        else { return nil }
        
        return Photo(
            id: id,
            url: url,
            uploadedBy: uploadedBy,
            timestamp: timestamp
        )
    }
}
