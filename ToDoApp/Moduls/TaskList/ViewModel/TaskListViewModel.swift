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
    var expandedIndexPath: IndexPath? { get set }
    var onLoadingStateChanged: ((Bool) -> Void)? {get set}
    
    func getNumberOfRows(in section: Int) -> Int
    func getNumberOfSections() -> Int
    func getTask(at index: IndexPath) -> Task
    func getTitle(for section: Int) -> String?
    func markTaskAsCompleted(at indexPath: IndexPath)
    func viewDidLoad()
    func addNewTaskTapped()
    func deleteTask(at index: IndexPath)
    func toggleCellExpansion(at index: IndexPath)
    func searchTasks(witn query: String)
    func toggleSectionCollapse(for section: Int)
    func editTask(at indexPath: IndexPath)
    func updateTask(task: Task, title: String, decription: String, date: Date)
    func refreshData()
}

final class TaskListViewModel: NSObject,  TaskListViewModelProtocol {
    //MARK: - Properies
    private let coordonator: TaskListCoordinatorProtocol
    private let coreDataStack: CoreDataStackProtocol
    private let dataService: DataServiceProtocol
    
    private var fetchedResultController: NSFetchedResultsController<Task>!
    private var collapsedSections: Set<String> = []
    var expandedIndexPath: IndexPath?
    
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    private var isLoading = false {
        didSet {
            onLoadingStateChanged?(isLoading)
        }
    }
    //MARK: - Init
    init(coordonator: TaskListCoordinatorProtocol,
         coreDataStack: CoreDataStackProtocol = CoreDataStack.shared,
         dataService: DataServiceProtocol = DataService() ) {
        self.coordonator = coordonator
        self.coreDataStack = coreDataStack
        self.dataService = dataService
        super.init()
    }
    
    //MARK: - Methods
    func getNumberOfSections() -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func getNumberOfRows(in section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else { return 0}
        if collapsedSections.contains(sectionInfo.name) {
            return 0
        }
        return sectionInfo.numberOfObjects

    }
    
    func getTitle(for section: Int) -> String? {
        guard let sectionInfo = fetchedResultController.sections?[section] else { return nil}
        
        return sectionInfo.name == "0" ? "Today" : "Completed"
    }
    
    func getTask(at index: IndexPath) -> Task {
        return fetchedResultController.object(at: index)
    }
    
    func viewDidLoad() {
        isLoading = true
        setupFetchedResultController()
        checkAndLoadInitialData()
        checkDatabaseDirectly(context: "viewDidLoad")

    }
    
    func addNewTaskTapped() {
        coordonator.showAddTaskScreen { [weak self] title, description, date in
            self?.createTask(title: title, description: description, date: date)
        }
    }
    
    func markTaskAsCompleted(at indexPath: IndexPath) {
        let task = getTask(at: indexPath)
        guard !task.isCompleted else { return }
        task.isCompleted = true
        coreDataStack.saveContext()
    }
    
    func toggleCellExpansion(at index: IndexPath) {
        if expandedIndexPath == index {
            expandedIndexPath = nil
        } else {
            expandedIndexPath = index
        }
        onDataUpdated?()
    }
    
    func toggleSectionCollapse(for section: Int) {
        guard let sectionID = fetchedResultController.sections?[section].name else { return }
        
        if collapsedSections.contains(sectionID) {
            collapsedSections.remove(sectionID)
        } else {
            collapsedSections.insert(sectionID)
        }
        onDataUpdated?()
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
    
    func editTask(at indexPath: IndexPath) {
        let task = getTask(at: indexPath)
        coordonator.showEditTaskScreen(task: task) { [weak self] (taskToUpdate, newTitle, newDescription, newDate) in
            self?.updateTask(task: taskToUpdate, title: newTitle, decription: newDescription, date: newDate)
        }
    }
    
    func updateTask(task: Task, title: String, decription: String, date: Date) {
        task.title = title
        task.taskDescription = decription
        task.creationDate = date
        coreDataStack.saveContext()
    }
    
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
        }
    }
    
    //MARK: - Private Methods
    private func checkAndLoadInitialData() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "isInitialDataLoaded") {
            
            print("--- ViewModel: First launch detected. Loading initial data...")
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.dataService.loadInitialTasks { result in
                    switch result {
                    case .success(let dtos):
                        self?.saveInitialTasksToCoreData(dtos: dtos) { success in
                            if success {
                                defaults.set(true, forKey: "isInitialDataLoaded")
                                print("--- ViewModel: UserDefaults flag set to true.")
                            }
                            
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.onError?("Failed to load initial data: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            print("--- ViewModel: Not a first launch. Data should be in Core Data.")
        }
    }
    
    private func saveInitialTasksToCoreData(dtos: [ToDoDTO], completion: @escaping (Bool) -> Void) {
        coreDataStack.performBackground { context in
            dtos.forEach { dto in
                let task = Task(context: context)
                task.id = Int64(dto.id)
                task.title = dto.todo
                task.isCompleted = dto.completed
                task.creationDate = Date()
                task.taskDescription = "Description for task \(dto.id)"
            }
            
            do {
                try context.save()
                print("--- ViewModel: SUCCESS - Saved initial tasks to Core Data.")
                completion(true) 
            } catch {
                print("--- ViewModel: ERROR - Failed to save initial tasks. Error: \(error)") 
                completion(false)
            }
        }
    }
    
    
    private func createTask(title: String, description: String, date: Date) {
        let context = coreDataStack.viewContext
        let newTask = Task(context: context)
        newTask.title = title
        newTask.creationDate = date
        newTask.isCompleted = false
        newTask.id = -1
        newTask.taskDescription = description
        
        coreDataStack.saveContext()
        checkDatabaseDirectly(context: "after creating task")

    }
    
    private func setupFetchedResultController() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        let sectionSort = NSSortDescriptor(key: "isCompleted", ascending: true)
        let dateSort = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sectionSort, dateSort]
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                             managedObjectContext: coreDataStack.viewContext,
                                                             sectionNameKeyPath: "sectionIdentifier",
                                                             cacheName: nil)
        fetchedResultController.delegate = self
        
        do {
              print("🚀 FRC: Performing fetch...")
              try fetchedResultController.performFetch()
              let objectCount = fetchedResultController.fetchedObjects?.count ?? 0
              print("✅ FRC: Perform fetch SUCCEEDED. Found \(objectCount) objects.")
          } catch {
              print("❌ FRC: Perform fetch FAILED with error: \(error)")
              onError?("Failed to fetch tasks: \(error.localizedDescription)")
          }
    }
    
    private func checkDatabaseDirectly(context: String) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            let count = try coreDataStack.viewContext.count(for: request)
            print("✅ DIAGNOSTIC [\(context)]: Found \(count) tasks directly in Core Data.")
        } catch {
            print("❌ DIAGNOSTIC [\(context)]: ERROR checking database directly: \(error)")
        }
    }
 
}

//MARK: - FRC Delegate
extension TaskListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        isLoading = false
        print("🔔 FRC Delegate: controllerDidChangeContent was called! Notifying view to update.")

        onDataUpdated?()
    }
}
