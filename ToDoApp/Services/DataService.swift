//
//  DataService.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import Foundation


enum DataError: Error {
    case fileNotFound
    case decodingError(Error)
}
protocol DataServiceProtocol {
    func loadInitialTasks(completion: @escaping ( Result<[ToDoDTO],DataError> )-> Void)
}

final class DataService: DataServiceProtocol {
    func loadInitialTasks(completion: @escaping (Result<[ToDoDTO], DataError>) -> Void) {
        print("--- DataService: Attempting to load todos.json...") 
        
        guard let url = Bundle.main.url(forResource: "todos", withExtension: "json") else {
            print("--- DataService: ERROR - JSON file not found in bundle.")
            completion(.failure(.fileNotFound))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(TodDoResponse.self, from: data)
            print("--- DataService: SUCCESS - Decoded \(response.todos.count) tasks from JSON.")
            completion(.success(response.todos))
        } catch {
            print("--- DataService: ERROR - Failed to decode JSON. Error: \(error)")
            completion(.failure(.decodingError(error)))
        }
    }
}
