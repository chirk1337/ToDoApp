//
//  TaskListCoordinator.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import UIKit

protocol TaskListCoordinatorProtocol {
    func showAddTaskScreen(completion: @escaping (String, String, Date) -> Void)
    func showEditTaskScreen(task: Task, completion: @escaping (Task, String, String, Date) -> Void)
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
    
    func showAddTaskScreen(completion: @escaping (String, String, Date) -> Void) {
        let addTaskVC = AddTaskViewController()
        addTaskVC.onTaskSave = completion
        
        let navController = UINavigationController(rootViewController: addTaskVC)
        navigationController.present(navController, animated: true)
    }
    
    func showEditTaskScreen(task: Task, completion: @escaping (Task, String, String, Date) -> Void) {
        let editTaskVC = AddTaskViewController()
        editTaskVC.taskToEdit = task
        
        editTaskVC.onTaskSave = { title, description, date in
        completion(task, title, description, date)
        }
        
        let navController = UINavigationController(rootViewController: editTaskVC)
        navigationController.present(navController, animated: true)
    }
    
    
}
