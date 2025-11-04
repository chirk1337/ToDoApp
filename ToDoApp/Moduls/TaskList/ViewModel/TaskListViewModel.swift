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
        return fetchedResultController.sections?.first?.numberOfObjects ?? 0

    }
    
    func getTask(at index: IndexPath) -> Task {
        return fetchedResultController.object(at: index)
    }
    
    func viewDidLoad() {
        setupFetchedResultController()
        checkAndLoadInitialData()
    }
    
    func addNewTaskTapped() {
        coordonator.showAddTaskAlert { [weak self] title in
            self?.createTask(title: title)
        }
    }
    
    func deleteTask(at index: IndexPath) {
        let task = getTask(at: index)
        coreDataStack.viewContext.delete(task)
        coreDataStack.saveContext()
    }
    
    func toggleTaskStatus(at index: IndexPath) {
        let task = getTask(at: index)
        task.isCompleted.toggle()
        coreDataStack.saveContext()
    }
    
    func searchTasks(witn query: String) {
        let predicate: NSPredicate?
        if query.isEmpty {
            predicate = nil
        } else {
            predicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        }
        fetchedResultController.fetchRequest.predicate = predicate
        
        do {
            try fetchedResultController.performFetch()
            onDataUpdated?()
        } catch {
            onError?("Error during search: \(error.localizedDescription)")
        }
    }
    
    
    private func checkAndLoadInitialData() {
        let key = "isInitialDataLoaded"
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: key) {
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.dataService.loadInitialTasks { result in
                    switch result {
                    case .success(let dtos):
                        self?.saveInitialTasksToCoreData(dtos: dtos)
                        defaults.set(true, forKey: key)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.onError?("Failed to load initial data: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func saveInitialTasksToCoreData(dtos: [ToDoDTO]) {
        coreDataStack.performBackground { context in
            dtos.forEach { dto in
            let task = Task(context: context)
                task.id = Int64(dto.id)
                task.title = dto.todo
                task.isCompleted = dto.completed
                task.creationDate = Date()
                task.taskDescription = ""
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save initial data: \(error)")
            }
        }
    }
    
    private func createTask(title: String) {
        let context = coreDataStack.viewContext
        let newTask = Task(context: context)
        newTask.title = title
        newTask.creationDate = Date()
        newTask.isCompleted = false
        newTask.id = -1
        newTask.taskDescription = ""
        
        coreDataStack.saveContext()
    }
    
    private func setupFetchedResultController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        let sortDescriptor1 = NSSortDescriptor(key: "isCompleted", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                             managedObjectContext: coreDataStack.viewContext,
                                                             sectionNameKeyPath: nil,
                                                             cacheName: nil)
        fetchedResultController.delegate = self
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            onError?("Failed to fetch tasks: \(error.localizedDescription)")
        }
    }
    
 
}
extension TaskListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onDataUpdated?()
    }
}
