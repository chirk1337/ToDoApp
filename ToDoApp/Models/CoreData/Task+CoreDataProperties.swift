//
//  Task+CoreDataProperties.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 05.11.2025.
//
//

public import Foundation
public import CoreData


public typealias TaskCoreDataPropertiesSet = NSSet

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var id: Int64
    @NSManaged public var isCompleted: Bool
    @NSManaged public var sectionIdentifier: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var title: String?

}

extension Task : Identifiable {

}
