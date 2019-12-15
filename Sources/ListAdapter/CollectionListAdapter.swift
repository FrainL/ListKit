//
//  CollectionListAdapter.swift
//  ListKit
//
//  Created by Frain on 2019/11/23.
//

public protocol CollectionListAdapter: ScrollListAdapter {
    var collectionList: CollectionList<SourceBase> { get }
}

@propertyWrapper
@dynamicMemberLookup
public struct CollectionList<Source: DataSource>: CollectionListAdapter, UpdatableDataSource
where Source.SourceBase == Source {
    public typealias Item = Source.Item
    public typealias SourceBase = Source
    
    var contextSetups = [(ListContext<Source>) -> Void]()
    
    public let source: Source
    public let coordinatorStorage = CoordinatorStorage<Source>()
    
    public var updater: Updater<Source> { source.updater }
    public var sourceBase: Source { source }
    public var collectionList: CollectionList<Source> { self }
    public var listCoordinator: ListCoordinator<Source> { sourceListCoordinator }
    public func makeListCoordinator() -> ListCoordinator<Source> {
        addToStorage(source.listCoordinator)
    }
    
    public var wrappedValue: Source { source }
    public var projectedValue: Source.Source { source.source }
    
    public subscript<Value>(dynamicMember path: KeyPath<Source, Value>) -> Value {
        source[keyPath: path]
    }
}

extension CollectionList: ListAdapter {
    static var rootKeyPath: ReferenceWritableKeyPath<Delegates, UICollectionViewDelegates> {
        \.collectionViewDelegates
    }
    
    static func toContext(_ view: CollectionView, _ listContext: ListContext<Source>) -> CollectionContext<Source> {
        .init(listView: view, coordinator: listContext.coordinator)
    }
    
    static func toSectionContext(_ view: CollectionView, _ listContext: ListContext<Source>, section: Int) -> CollectionSectionContext<Source> {
        .init(
            listView: view,
            coordinator: listContext.coordinator,
            section: section - listContext.sectionOffset,
            sectionOffset: listContext.sectionOffset
        )
    }
    
    static func toItemContext(_ view: CollectionView, _ listContext: ListContext<Source>, path: PathConvertible) -> CollectionItemContext<Source> {
        .init(
            listView: view,
            coordinator: listContext.coordinator,
            section: path.section - listContext.sectionOffset,
            sectionOffset: listContext.sectionOffset,
            item: path.item - listContext.itemOffset,
            itemOffset: listContext.itemOffset
        )
    }
}