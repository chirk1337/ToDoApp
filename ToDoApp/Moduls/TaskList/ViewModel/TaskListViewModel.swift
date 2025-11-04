//
//  TaskListViewModel.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import Foundation
import CoreData

protocol TaskListViewModelProtocol {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    
    func getNumberOfRows() -> Int
    func getTask(at index: IndexPath) -> Task
    
    func viewDidLoad()
    func addNewTaskTapped()
    func deleteTask(at index: IndexPath)
    func toggleTaskStatus(at index: IndexPath)
    func searchTasks(witn query: String)
}

final class TaskListViewModel: NSObject,  TaskListViewModelProtocol {
    private let coordonator: TaskListCoordinatorProtocol
    private let coreDataStack: CoreDataStackProtocol
    private let dataService: DataServiceProtocol
    
    private var fetchedResultController: NSFetchedResultsController<Task>!
    
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init(coordonator: TaskListCoordinatorProtocol,
         coreDataStack: CoreDataStackProtocol = CoreDataStack.shared,
         dataService: DataServiceProtocol = DataService() ) {
        self.coordonator = coordonator
        self.coreDataStack = coreDataStack
        self.dataService = dataService
        super.init()
    }
    
    func getNumberOfRows() -> Int {
        <#code#>
    }
    
    func getTask(at index: IndexPath) -> Task {
        <#code#>
    }
    
    func viewDidLoad() {
        <#code#>
    }
    
    func addNewTaskTapped() {
        <#code#>
    }
    
    func deleteTask(at index: IndexPath) {
        <#code#>
    }
    
    func toggleTaskStatus(at index: IndexPath) {
        <#code#>
    }
    
    func searchTasks(witn query: String) {
        <#code#>
    }
 
}
extension TaskListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onDataUpdated?()
    }
}
