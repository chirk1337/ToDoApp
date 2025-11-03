//
//  ToDoDTO.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import Foundation

struct TodDoResponse: Codable {
    let todos: [ToDoDTO]
}

struct ToDoDTO: Codable {
    let id: Int
    let todo: String
    let completed: Bool
}
