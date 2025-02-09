//
//  Project.swift
//  PROPS
//
//  Created by Elisaveta Egorova on 08.02.2025.
//

import Foundation

struct Project: Identifiable, Codable {
    let id: String
    let name: String
    var createdAt: Date?
    
    init(id: String = UUID().uuidString,
         name: String,
         createdAt: Date? = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

// MARK: - Equatable
extension Project: Equatable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Project: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Default Projects
extension Project {
    static let defaultProjects = [
        Project(name: "Солдатская мать"),
        Project(name: "Тень Чикатило"),
        Project(name: "Райки"),
        Project(name: "След Чикатило")
    ]
}
