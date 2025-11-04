//
//  TaskListCoordinator.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import UIKit

protocol TaskListCoordinatorProtocol {
    func showAddTaskAlert(completion: @escaping (String) -> Void)
}


final class TaskListCoordinator: TaskListCoordinatorProtocol {
    
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewModel = TaskListViewModel(coordonator: self)
        let viewController = TaskListViewController(viewModel: viewModel)
        
        navigationController.navigationBar.prefersLargeTitles = true
        viewController.title = "My Tasks"
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showAddTaskAlert(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "New Task",
                                      message: "Enter the title for your new task",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., Buy milk"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let textField = alert.textFields?.first, let text = textField.text, !text.isEmpty {
                completion(text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        navigationController.present(alert, animated: true)
    }
    
    
}
