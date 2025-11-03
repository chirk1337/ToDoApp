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
        guard let url = Bundle.main.url(forResource: "todos", withExtension: "json") else {
            completion(.failure(.fileNotFound))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(TodDoResponse.self, from: data)
            completion(.success(response.todos))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }
}
