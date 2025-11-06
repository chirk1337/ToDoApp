//
//  Task+CoreDataClass.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 05.11.2025.
//
//

public import Foundation
public import CoreData

public typealias TaskCoreDataClassSet = NSSet

@objc(Task)
public class Task: NSManagedObject {
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        self.sectionIdentifier = self.isCompleted ? "1" : "0"
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.sectionIdentifier = self.isCompleted ? "1" : "0"
    }
    
    public override func willSave() {
        super.willSave()
        if !isDeleted {
            let newIndetifier = self.isCompleted ? "1" : "0"
            if self.sectionIdentifier != newIndetifier {
                self.sectionIdentifier = newIndetifier
            }
        }
    }
}
