//
//  ViewController.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import UIKit
import Combine

class ViewController: UIViewController {

    private var repository: CoreDataRepostoryImpl<Todo>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let contextProvider: DBContextProvider = DefaultDBContextProvider()
        let entityMapper = TodoEntityMapper()
        let repository = DBRepository(contextSource: contextProvider,
                                autoUpdateSearchRequest: nil,
                                entityMapper: entityMapper)
        self.repository = repository
        self.prepareForExample(repository)
    }

    func prepareForExample(_ repository: CoreDataRepostoryImpl<Todo>) {
        let example = ExampleCase(repository: repository)
        let todos = example.generateMock()
//        print("---> TODOS: \(todos)")
//        example.startSaving(todos)
//        example.startReading()
        example.deleteAllData()
    }
}


final class ExampleCase {
    private var repository: CoreDataRepostoryImpl<Todo>
    private var saveSubscriber: AnyCancellable?
    private var readSubscriber: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init(repository: CoreDataRepostoryImpl<Todo>) {
        self.repository = repository
    }

    func generateMock() -> [Todo] {
        var todos: [Todo] = []
        for index in 0...20000 {
            todos.append(Todo(uuid: String(index),
                              title: "Title: \(index)",
                              description: "Description: \(index)",
                              isCompleted: Bool.random()))
        }
        return todos
    }

    func startSaving(_ todos: [Todo]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        self.repository.save(todos)
            .subscribe(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("FAILURE: \(error.localizedDescription)")

                case .finished:
                    break
                }
            } receiveValue: { _ in
                print("FINISHED: \(CFAbsoluteTimeGetCurrent() - startTime)")
            }
            .store(in: &self.cancellables)
    }

    func startReading() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        self.repository.present(by: TodosSearchRequest(sortDescriptors: [sortDescriptor]))
            .subscribe(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("FAILURE: \(error.localizedDescription)")
                    break

                case .finished:
                    break
                }
            }, receiveValue: { todos in
                print("FINISHED: \(CFAbsoluteTimeGetCurrent() - startTime) with todos count: \(todos.count)")
            })
            .store(in: &self.cancellables)
    }

    func deleteAllData() {
        let startTime = CFAbsoluteTimeGetCurrent()
        self.repository.eraseAllData()
            .subscribe(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break

                case .failure(let error):
                    print("FAILURE: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                print("FINISHED DELETE OBJECTS: \(CFAbsoluteTimeGetCurrent() - startTime)")
            }
            .store(in: &self.cancellables)
    }
}

class TodosSearchRequest: RepositorySearchRequest {

    var predicate: NSPredicate?
    var sortDescriptors: [NSSortDescriptor]

    init(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }
}
