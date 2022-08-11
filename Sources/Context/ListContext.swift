//
//  ListContext.swift
//  ListKit
//
//  Created by Frain on 2020/8/2.
//

import Foundation

@dynamicMemberLookup
public protocol Context {
    associatedtype Base: DataSource
    associatedtype List

    var source: Base.SourceBase.Source { get }
    var listView: List { get }
}

public struct ListContext<List, Base: DataSource>: Context {
    public let listView: List
    let context: ListCoordinatorContext<Base.SourceBase>
    let root: CoordinatorContext

    public var source: Base.SourceBase.Source { context.listCoordinator.source }
}

public struct ListIndexContext<List, Base: DataSource, Index>: Context {
    public let listView: List
    public let index: Index
    public let offset: Index
    let context: ListCoordinatorContext<Base.SourceBase>
    let root: CoordinatorContext

    public var source: Base.SourceBase.Source { context.listCoordinator.source }
}

public extension DataSource {
    typealias ListSectionContext<List: ListView> = ListIndexContext<List, Self, Int>
    typealias ListModelContext<List: ListView> = ListIndexContext<List, Self, IndexPath>
}

public extension Context {
    subscript<Value>(dynamicMember keyPath: KeyPath<Base.SourceBase.Source, Value>) -> Value {
        source[keyPath: keyPath]
    }
}

public extension ListIndexContext where Index == Int {
    var section: Int { index - offset }
}

public extension ListIndexContext where Index == IndexPath {
    var section: Int { index.section - offset.section }
    var item: Int { index.item - offset.item }

    var model: Base.SourceBase.Model {
        context.listCoordinator.model(at: index.offseted(offset, plus: false))
    }
}

public extension ListIndexContext where Base: ModelCachedDataSource, Index == IndexPath {
    var modelCache: Base.ModelCache { cache() }
}

extension ListIndexContext where Index == IndexPath {
    func setNestedCache(update: @escaping (Any) -> Void) {
        root.modelNestedCache[index.section][index.item] = update
    }

    func cache<Cache>() -> Cache {
        if let cache = root.modelCaches[index.section][index.item] as? Cache { return cache }
        return context.listCoordinator.cache(
            for: &root.modelCaches[index.section][index.item],
            at: index,
            in: context.listDelegate
        )
    }
}
