//
//  DBRepository.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import CoreData
import Combine

final class DBRepository<DomainModel, DBEntity>: CoreDataRepostoryImpl<DomainModel>, NSFetchedResultsControllerDelegate {

    // MARK: - Instance Properties

    private let associatedEntityName: String
    private let contextSource: DBContextProvider
    private let entityMapper: DBEntityMapper<DomainModel, DBEntity>
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private var searchedData: AnyPublisher<[DomainModel], Error>?
    private var applyChangesSubscriber: AnyCancellable?

    // MARK: - Init

    init(contextSource: DBContextProvider,
         autoUpdateSearchRequest: RepositorySearchRequest?,
         entityMapper: DBEntityMapper<DomainModel, DBEntity>
    ) {
        self.contextSource = contextSource
        self.associatedEntityName = String(describing: DBEntity.self)
        self.entityMapper = entityMapper

        super.init()
        guard let request = autoUpdateSearchRequest else { return }
        self.fetchedResultsController = configureActualSearchedDataUpdating(request)
    }

    // MARK: - Instance Methods

    private func applyChanges(context: NSManagedObjectContext,
                              mergePolicy: Any = NSMergeByPropertyObjectTrumpMergePolicy
    ) -> AnyPublisher<Void, Error> {
        Future { promise in
            context.mergePolicy = mergePolicy
            switch context.hasChanges {
            case true:
                do {
                    try context.save()
                } catch {
                    // TODO: - Log to Crashlytics
                    promise(.failure(CoreDataError.saveError(error)))
                }
                // TODO: - Log to Crashlytics
                promise(.success(()))
            case false:
                // TODO: - Log to Crashlytics
                promise(.failure(CoreDataError.noChangesInRepository))
            }
        }
        .eraseToAnyPublisher()
    }

    private func saveIn(data: [DomainModel], clearBeforeSaving: RepositorySearchRequest?) -> AnyPublisher<Void, Error> {
        Future { promise in
            self.contextSource.performBackgroundTask() { context in

                if let clearBeforeSaving = clearBeforeSaving {
                let clearFetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
                clearFetchRequest.predicate = clearBeforeSaving.predicate
                clearFetchRequest.includesPropertyValues = false
                (try? context.fetch(clearFetchRequest))?.forEach({ context.delete($0) })
                }

                var existingObjects: [String: DBEntity] = [:]
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)

                (try? context.fetch(fetchRequest) as? [DBEntity])?.forEach({
                let accessor = self.entityMapper.entityAccessorKey($0)
                existingObjects[accessor] = $0
                })

                data.forEach({
                    let accessor = self.entityMapper.entityAccessorKey($0)
                    let entityForUpdate: DBEntity? = existingObjects[accessor] ?? NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? DBEntity
                    guard let entity = entityForUpdate else { return }
                    self.entityMapper.update(entity, by: $0)
                })
                self.applyChangesSubscriber = self.applyChanges(context: context)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            promise(.failure(error))

                        case .finished:
                            break
                        }
                    } receiveValue: { _ in
                        promise(.success(()))
                    }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: -

    override func save(_ objects: [DomainModel]) -> AnyPublisher<Void, Error> {
        self.saveIn(data: objects, clearBeforeSaving: nil)
    }

    override func save(_ objects: [DomainModel], clearBeforeSaving: RepositorySearchRequest) -> AnyPublisher<Void, Error> {
        self.saveIn(data: objects, clearBeforeSaving: clearBeforeSaving)
    }

    override func present(by request: RepositorySearchRequest) -> AnyPublisher<[DomainModel], Error> {
        Future { promise in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
            fetchRequest.predicate = request.predicate
            fetchRequest.sortDescriptors = request.sortDescriptors
            self.contextSource.performBackgroundTask() { context in
                do {
                    let rawData = try context.fetch(fetchRequest)
                    guard rawData.isEmpty == false else {
                        assertionFailure(CoreDataError.noDataInRepository.localizedDescription)
                        promise(.success([]))
                        return
                    }
                    guard let results = rawData as? [DBEntity] else {
                        assertionFailure(CoreDataError.entityTypeError.localizedDescription)
                        promise(.success([]))
                        return
                    }
                    let converted = results.compactMap({ return self.entityMapper.convert($0) })
                    promise(.success(converted))
                } catch {
                    // TODO: - Log to Crashlytics
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    override func delete(by request: RepositorySearchRequest) -> AnyPublisher<Void, Error> {
        Future { promise in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
            fetchRequest.predicate = request.predicate
            fetchRequest.includesPropertyValues = false
            self.contextSource.performBackgroundTask() { context in
                let results = try? context.fetch(fetchRequest)
                results?.forEach({ context.delete($0) })
                self.applyChangesSubscriber = self.applyChanges(context: context)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            promise(.failure(error))

                        case .finished:
                            break
                        }
                    } receiveValue: { _ in
                        promise(.success(()))
                    }
            }
        }
        .eraseToAnyPublisher()
    }

    override func eraseAllData() -> AnyPublisher<Void, Error> {
        Future { promise in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.associatedEntityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            batchDeleteRequest.resultType = .resultTypeObjectIDs
            self.contextSource.performBackgroundTask({ context in
                do {
                    let result = try context.execute(batchDeleteRequest)
                    guard let deleteResult = result as? NSBatchDeleteResult,
                          let ids = deleteResult.result as? [NSManagedObjectID]
                    else {
                        promise(.failure(CoreDataError.noChangesInRepository))
                        return
                    }

                    let changes = [NSDeletedObjectsKey: ids]
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [self.contextSource.mainQueueContext()]
                    )
                    promise(.success(()))
                    return
                } catch {
                    // TODO: - Log to Crashlytics
                    promise(.failure(CoreDataError.deleteError(error)))
                }
            })
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - DBRepository Extension

extension DBRepository {

    // MARK: - Instance Methods

    private func configureActualSearchedDataUpdating(_ request: RepositorySearchRequest) -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: associatedEntityName)

        fetchRequest.predicate = request.predicate
        fetchRequest.sortDescriptors = request.sortDescriptors

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: contextSource.mainQueueContext(),
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        if let content = fetchedResultsController.fetchedObjects as? [DBEntity] {
            self.updateObservableContent(content)
        }
        return fetchedResultsController
    }

    private func updateObservableContent(_ content: [DBEntity]) {
        let converted = content.compactMap({ return self.entityMapper.convert($0) })
        self.searchedData = Result.Publisher(converted).eraseToAnyPublisher()
    }
}
