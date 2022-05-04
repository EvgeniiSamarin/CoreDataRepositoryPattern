//
//  CoreDataStorage.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import CoreData
import Combine

class CoreDataRepostoryImpl<Entity>:NSObject, CoreDataRepository {

    // MARK: - Typealiases

    typealias Entity = Entity

    // MARK: - Instance Properties

    var actualSearchedData: AnyPublisher<[Entity], Error>?

    // MARK: - Instance Methods

    func save(_ objects: [Entity]) -> AnyPublisher<Void, Error> {
        fatalError("save(_ objects:) must be overrided")
    }

    func save(_ objects: [Entity], clearBeforeSaving: RepositorySearchRequest) -> AnyPublisher<Void, Error> {
        fatalError("save(_ objects:, clearBeforeSaving:) must be overrided")
    }

    func present(by request: RepositorySearchRequest) -> AnyPublisher<[Entity], Error> {
        fatalError("present(by request:) must be overrided")
    }

    func delete(by request: RepositorySearchRequest) -> AnyPublisher<Void, Error> {
        fatalError("delete(by request:) must be overrided")
    }

    func eraseAllData() -> AnyPublisher<Void, Error> {
        fatalError("eraseAllData() must be overrided")
    }
}
