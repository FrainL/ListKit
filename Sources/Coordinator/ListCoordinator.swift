//
//  ListCoordinator.swift
//  ListKit
//
//  Created by Frain on 2019/11/25.
//

import Foundation

public class ListCoordinator<Model> {
    typealias Indices = ContiguousArray<(index: Int, isFake: Bool)>
    typealias Context = ListCoordinatorContext<Model>

    struct WeakContext {
        weak var context: ListCoordinatorContext<Model>?
    }

//    let update: ListUpdate<SourceBase>.Whole
//    let differ: ListDiffer<SourceBase>
    var options: ListOptions
//    var source: Any!

    weak var storage: CoordinatorStorage<Model>?
    weak var currentCoordinatorUpdate: ListCoordinatorUpdate<Model>?
    var listContexts = [WeakContext]()

    lazy var sourceType = configSourceType()

//    var sourceBaseType: Any.Type { SourceBase.self }
    var isSectioned: Bool {
        options.preferSection || listContexts.contains {
            $0.context?.listDelegate.hasSectionIndex == true
        }
    }

    init(
//        source: SourceBase.Source!
//        update: ListUpdate<SourceBase>.Whole,
//        differ: ListDiffer<SourceBase> = .none,
        options: ListOptions = .none
    ) {
//        self.update = update
//        self.differ = differ
        self.options = options
//        self.source = source
    }

//    init(_ sourceBase: SourceBase) {
//        self.differ = sourceBase.listDiffer
//        self.update = sourceBase.listUpdate
//        self.options = sourceBase.listOptions
//        self.source = sourceBase.source
//    }

    func numbersOfSections() -> Int { notImplemented() }
    func numbersOfModel(in section: Int) -> Int { notImplemented() }

    func model(at indexPath: IndexPath) -> Model { notImplemented() }

//    func cache<ModelCache>(
//        for cached: inout Any?,
//        at indexPath: IndexPath,
//        in delegate: ListDelegate
//    ) -> ModelCache {
//        guard let getCache = delegate.getCache as? (Model) -> ModelCache else {
//            fatalError("\(SourceBase.self) no cache with \(ModelCache.self)")
//        }
//        let cache = getCache(model(at: indexPath))
//        cached = cache
//        return cache
//    }

    func configSourceType() -> SourceType { notImplemented() }

    // Selectors:
    func configExtraSelector(delegate: ListDelegate) -> Set<Selector>? { nil }

    @discardableResult
    func apply<Input, Output>(
        _ selector: Selector,
        for context: Context,
        root: CoordinatorContext,
        view: AnyObject,
        with input: Input
    ) -> Output? {
        guard let rawClosure = context.listDelegate.functions[selector],
              let closure = rawClosure as? (AnyObject, Context, CoordinatorContext, Input) -> Output
        else { return nil }
        return closure(view, context, root, input)
    }

    // swiftlint:disable function_parameter_count
    @discardableResult
    func apply<Input, Output, Index: ListIndex>(
        _ selector: Selector,
        for context: Context,
        root: CoordinatorContext,
        view: AnyObject,
        with input: Input,
        index: Index,
        _ offset: Index
    ) -> Output? {
        guard let rawClosure = context.listDelegate.functions[selector],
              let closure = rawClosure as? (AnyObject, Context, CoordinatorContext, Input, Index, Index) -> Output
        else { return nil }
        return closure(view, context, root, input, index, offset)
    }
    // swiftlint:enable function_parameter_count

    // Updates:
//    func identifier(for sourceBase: SourceBase) -> [AnyHashable] {
//        let id = ObjectIdentifier(sourceBaseType)
//        guard let identifier = differ.identifier else { return [id, sourceType] }
//        return [id, sourceType, identifier(sourceBase)]
//    }
//
//    func equal(lhs: SourceBase, rhs: SourceBase) -> Bool {
//        differ.areEquivalent?(lhs, rhs) ?? true
//    }
//
//    func update(
//        update: ListUpdate<SourceBase>,
//        options: ListOptions? = nil
//    ) -> ListCoordinatorUpdate<SourceBase> {
//        notImplemented()
//    }

    func update(
        from coordinator: ListCoordinator<Model>
//        updateWay: ListUpdateWay<Model>?
    ) -> ListCoordinatorUpdate<Model> {
        .init(self, options: (coordinator.options, options))
    }
}

extension ListCoordinator {
    func contextAndUpdates(update: CoordinatorUpdate) -> [(CoordinatorContext, CoordinatorUpdate)]? {
        var results: [(CoordinatorContext, CoordinatorUpdate)]?
        for context in listContexts {
            guard let context = context.context else { continue }
            if context.listView != nil {
                results = results.map { $0 + [(context, update)] } ?? [(context, update)]
            } else if let parentUpdate = context.update?(context.index, update) {
                results = results.map { $0 + parentUpdate } ?? parentUpdate
            }
        }
        return results
    }

    func offsetAndRoot(offset: IndexPath, list: ListView) -> [(IndexPath, CoordinatorContext)] {
        var results = [(IndexPath, CoordinatorContext)]()
        for context in self.listContexts {
            guard let context = context.context else { continue }
            if context.listView === list {
                results.append((offset, context))
            }

            results += context.contextAtIndex?(context.index, offset, list) ?? []
        }
        return results
    }

    func resetDelegates() {
        listContexts.forEach { $0.context?.reconfig() }
    }
}
