//
//  DBEntityMapper.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import Foundation

class DBEntityMapper<DomainModel, Entity> {

    // MARK: - Instance Methods

    func convert(_ entity: Entity) -> DomainModel? {
        fatalError("convert(_ entity:) must be overrided")
    }
    func update(_ entity: Entity, by model: DomainModel) {
        fatalError("update(_ entity:, by model:) must be overrided")
    }
    func entityAccessorKey(_ entity: Entity) -> String {
        fatalError("entityAccessorKey(_ entity:) must be overrided")
    }
    func entityAccessorKey(_ object: DomainModel) -> String {
        fatalError("entityAccessorKey(_ object:) must be overrided")
    }
}
