//
//  ToDoAppTests.swift
//  ToDoAppTests
//
//  Created by Анатолий Чириков on 03.11.2025.
//

import XCTest
import CoreData
@testable import ToDoApp

class MockCoreDataStack: CoreDataStackProtocol {
    lazy var persistantContainer: NSPersistentContainer = {
        let bundles = [Bundle.main, Bundle(for: MockCoreDataStack.self)]
        
        guard let model = NSManagedObjectModel.mergedModel(from: bundles) else {
            fatalError("Failed to load merged model")
        }
        
        let container = NSPersistentContainer(name: "ToDoAppTest", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistantContainer.viewContext
    }
    
    func performBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistantContainer.performBackgroundTask(block)
    }
    
    func saveContext() {
        let context = viewContext
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    fatalError("Failed to save: \(error)")
                }
            }
        }
    }
}

class MockTaskListCoordinator: TaskListCoordinatorProtocol {
    var wasShowAddTaskScreenCalled: Bool = false
    var wasSHowEditTaskScreenCalled: Bool = false
    
    var addTaskCompletion: ((String, String, Date) -> Void)?
    var editTaskCompletion: ((Task, String, String, Date) -> Void)?
    
    func showAddTaskScreen(completion: @escaping (String, String, Date) -> Void) {
        wasShowAddTaskScreenCalled = true
        self.addTaskCompletion = completion
    }
    
    func showEditTaskScreen(task: Task, completion: @escaping (Task, String, String, Date) -> Void) {
        wasSHowEditTaskScreenCalled = true
        self.editTaskCompletion = completion
    }
}

final class ToDoAppTests: XCTestCase {
    var viewModel: TaskListViewModel!
    var mockCoreDataStack: MockCoreDataStack!
    var mockCoordinator: MockTaskListCoordinator!
    
    override func setUp() {
        super.setUp()
        
        mockCoordinator = MockTaskListCoordinator()
        mockCoreDataStack = MockCoreDataStack()
        
        // Очищаем данные ДО создания ViewModel
        clearAllTasks()
        
        viewModel = TaskListViewModel(coordonator: mockCoordinator,
                                      coreDataStack: mockCoreDataStack,
                                      dataService: DataService())
        
        viewModel.viewDidLoad()
        
        // Даем время на инициализацию FRC
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    override func tearDown() {
        clearAllTasks()
        viewModel = nil
        mockCoordinator = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    func testAddNewTask_ShouldCallCoordinatorAndIncreaseTaskCount() {
        // Arrange
        let initialCount = getTotalTaskCount()
        print("📊 Initial count: \(initialCount)")
        
        // Act
        viewModel.addNewTaskTapped()
        XCTAssertTrue(mockCoordinator.wasShowAddTaskScreenCalled, "Координатор должен быть вызван")
        
        // Симулируем ответ пользователя
        mockCoordinator.addTaskCompletion?("Новая задача", "Описание", Date())
        
        // Ждем обновления
        Thread.sleep(forTimeInterval: 0.2)
        
        // Assert
        let newCount = getTotalTaskCount()
        print("📊 New count: \(newCount)")
        
        XCTAssertEqual(newCount, initialCount + 1, "Должна добавиться одна задача")
        
        let task = findTask(withTitle: "Новая задача")
        XCTAssertNotNil(task, "Задача должна существовать")
        XCTAssertEqual(task?.title, "Новая задача")
        XCTAssertFalse(task?.isCompleted ?? true)
    }
    
    func testMarkTaskAsCompleted_ShouldUpdateTask() {
        // Arrange
        addTaskForTest(title: "Задача для выполнения")
        
        guard let taskInfo = findTaskWithIndexPath(title: "Задача для выполнения") else {
            XCTFail("Задача не найдена")
            return
        }
        
        print("📌 Found task at section: \(taskInfo.indexPath.section), row: \(taskInfo.indexPath.row)")
        XCTAssertFalse(taskInfo.task.isCompleted, "Pre-condition: Задача должна быть не выполнена")
        
        // Act
        viewModel.markTaskAsCompleted(at: taskInfo.indexPath)
        Thread.sleep(forTimeInterval: 0.2)
        
        // Assert
        let updatedTask = findTask(withTitle: "Задача для выполнения")
        XCTAssertNotNil(updatedTask, "Задача должна существовать")
        XCTAssertTrue(updatedTask?.isCompleted ?? false, "Задача должна быть помечена как выполненная")
    }
    
    func testDeleteTask_ShouldRemoveTask() {
        // Arrange
        addTaskForTest(title: "Задача для удаления")
        
        let initialCount = getTotalTaskCount()
        XCTAssertGreaterThan(initialCount, 0, "Pre-condition: Должна быть хотя бы одна задача")
        
        guard let taskInfo = findTaskWithIndexPath(title: "Задача для удаления") else {
            XCTFail("Задача не найдена")
            return
        }
        
        // Act
        viewModel.deleteTask(at: taskInfo.indexPath)
        Thread.sleep(forTimeInterval: 0.2)
        
        // Assert
        let newCount = getTotalTaskCount()
        XCTAssertEqual(newCount, initialCount - 1, "Задача должна быть удалена")
        
        let deletedTask = findTask(withTitle: "Задача для удаления")
        XCTAssertNil(deletedTask, "Задача не должна существовать")
    }
    
    func testSearchTasks_ShouldFilterResults() {
        // Arrange
        addTaskForTest(title: "Купить молоко")
        addTaskForTest(title: "Выгулять собаку")
        addTaskForTest(title: "Купить хлеб")
        
        let initialCount = getTotalTaskCount()
        XCTAssertEqual(initialCount, 3, "Pre-condition: Должно быть 3 задачи")
        
        // Act - поиск
        viewModel.searchTasks(witn: "Купить")
        Thread.sleep(forTimeInterval: 0.2)
        
        // Assert - результаты поиска
        let filteredCount = getTotalTaskCount()
        XCTAssertEqual(filteredCount, 2, "Должно быть найдено 2 задачи с 'Купить'")
        
        let task1 = findTask(withTitle: "Купить молоко")
        let task2 = findTask(withTitle: "Купить хлеб")
        XCTAssertNotNil(task1, "Задача 'Купить молоко' должна быть найдена")
        XCTAssertNotNil(task2, "Задача 'Купить хлеб' должна быть найдена")
        
        // Act - сброс поиска
        viewModel.searchTasks(witn: "")
        Thread.sleep(forTimeInterval: 0.2)
        
        // Assert - все задачи снова видны
        let resetCount = getTotalTaskCount()
        XCTAssertEqual(resetCount, 3, "После сброса должно быть 3 задачи")
    }
    
    // MARK: - Helper Methods
    
    private func addTaskForTest(title: String) {
        let context = mockCoreDataStack.viewContext
        
        context.performAndWait {
            let task = Task(context: context)
            task.title = title
            task.taskDescription = "Test description"
            task.creationDate = Date()
            task.isCompleted = false
            
            do {
                try context.save()
                print("✅ Task '\(title)' saved successfully")
            } catch {
                XCTFail("Failed to save task: \(error)")
            }
        }
        
        // Ждем обновления FRC
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    private func clearAllTasks() {
        let context = mockCoreDataStack.viewContext
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            
            do {
                let tasks = try context.fetch(fetchRequest)
                print("🗑️ Deleting \(tasks.count) tasks")
                
                for task in tasks {
                    context.delete(task)
                }
                
                if context.hasChanges {
                    try context.save()
                }
                
                print("✅ All tasks cleared")
            } catch {
                print("❌ Failed to clear tasks: \(error)")
            }
        }
        
        // Даем время на обработку
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    private func getTotalTaskCount() -> Int {
        var total = 0
        let sections = viewModel.getNumberOfSections()
        print("📊 Total sections: \(sections)")
        
        for section in 0..<sections {
            let rows = viewModel.getNumberOfRows(in: section)
            print("📊 Section \(section) has \(rows) rows")
            total += rows
        }
        
        return total
    }
    
    private func findTask(withTitle title: String) -> Task? {
        for section in 0..<viewModel.getNumberOfSections() {
            for row in 0..<viewModel.getNumberOfRows(in: section) {
                let task = viewModel.getTask(at: IndexPath(row: row, section: section))
                if task.title == title {
                    return task
                }
            }
        }
        return nil
    }
    
    private func findTaskWithIndexPath(title: String) -> (task: Task, indexPath: IndexPath)? {
        for section in 0..<viewModel.getNumberOfSections() {
            for row in 0..<viewModel.getNumberOfRows(in: section) {
                let indexPath = IndexPath(row: row, section: section)
                let task = viewModel.getTask(at: indexPath)
                if task.title == title {
                    return (task, indexPath)
                }
            }
        }
        return nil
    }
}
