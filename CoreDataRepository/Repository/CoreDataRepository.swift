//
//  CoreDataRepository.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import CoreData
import Combine

protocol CoreDataRepository {

    // MARK: - Instance Properties

    associatedtype Entity
    var actualSearchedData: AnyPublisher<[Entity], Error>? { get }

    // MARK: - Instance Methods

//    func object (_ id: NSManagedObjectID) -> AnyPublisher<Entity, Error>
//    func add(_ body: @escaping (inout Entity) -> Void) -> AnyPublisher<Entity, Error>
//    func update(_ entity: Entity) -> AnyPublisher<Void, Error>
//    func delete(_ entity: Entity) -> AnyPublisher<Void, Error>

    func save(_ objects: [Entity]) -> AnyPublisher<Void, Error>
    func save(_ objects: [Entity], clearBeforeSaving: RepositorySearchRequest) -> AnyPublisher<Void, Error>
    func present(by request: RepositorySearchRequest) -> AnyPublisher<[Entity], Error>
    func delete(by request: RepositorySearchRequest) -> AnyPublisher<Void, Error>
    func eraseAllData() -> AnyPublisher<Void, Error>
}
