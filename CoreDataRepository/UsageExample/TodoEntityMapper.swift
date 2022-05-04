//
//  TodoEntityMapper.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import Foundation
import CoreData

final class TodoEntityMapper: DBEntityMapper<Todo, TodoEntity> {

    // MARK: - Instance Methods

    override func convert(_ entity: TodoEntity) -> Todo? {
        guard let title = entity.title,
              let id = entity.id,
              let description = entity.descriptions
        else {
            return nil
        }
        return Todo(uuid: id,
                    title: title,
                    description: description,
                    isCompleted: entity.isCompleted)
    }

    override func update(_ entity: TodoEntity, by model: Todo) {
        entity.id = model.uuid
        entity.title = model.title
        entity.descriptions = model.description
        entity.isCompleted = model.isCompleted

      // MARK: - Add relationships if needed
//      guard let context = entity.managedObjectContext else { return }
    }
   
    override func entityAccessorKey(_ object: Todo) -> String {
        object.uuid
    }

    override func entityAccessorKey(_ entity: TodoEntity) -> String {
        entity.id ?? ""
    }
}
