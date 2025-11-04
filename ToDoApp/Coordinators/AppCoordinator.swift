//
//  AppCoordinator.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import UIKit


final class AppCoordinator {
    
    private let window: UIWindow
    private var taskListCoordinator: TaskListCoordinator?
    
    init(window: UIWindow, taskListCoordinator: TaskListCoordinator? = nil) {
        self.window = window
    }
    
    func start() {
        let navigationController = UINavigationController()
        taskListCoordinator = TaskListCoordinator(navigationController: navigationController)
        taskListCoordinator?.start()
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
