//
//  Context.swift
//  SundayListKit
//
//  Created by Frain on 2019/7/26.
//  Copyright © 2019 Frain. All rights reserved.
//

public protocol Context {
    associatedtype List: ListView
    associatedtype Snapshot
    
    var listView: List { get }
    var snapshot: Snapshot { get }
    var indexPath: IndexPath { get }
    var offset: IndexPath { get }
}

public extension Context {
    var listIndexPath: IndexPath {
        return indexPath.addingOffset(offset)
    }
    
    var cell: List.Cell? {
        return listView.cellForItem(at: listIndexPath)
    }
}

public extension Context where Snapshot: SectionSnapshot {
    var item: Snapshot.Item {
        return snapshot.item(at: indexPath)
    }
}

public extension Context where Snapshot: ListSnapshot {
    var subSnapshot: Snapshot.Element.SourceSnapshot {
        return snapshot.elementsSnapshot(at: indexPath)
    }
    
    var item: Snapshot.Element.Item {
        return snapshot.item(at: indexPath)
    }
}

public struct CollectionContext<Snapshot>: Context {
    public typealias List = UICollectionView
    
    public let snapshot: Snapshot
    public let indexPath: IndexPath
    public let offset: IndexPath
    public let listView: List
    
    init(listView: List, indexPath: IndexPath, offset: IndexPath = .default, snapshot: Snapshot) {
        self.snapshot = snapshot
        self.indexPath = indexPath
        self.offset = offset
        self.listView = listView
    }
}

public struct TableContext<Snapshot>: Context {
    public typealias List = UITableView
    
    public var snapshot: Snapshot
    public var indexPath: IndexPath
    public var offset: IndexPath
    public var listView: UITableView
    
    init(listView: List, indexPath: IndexPath, offset: IndexPath = .default, snapshot: Snapshot) {
        self.snapshot = snapshot
        self.indexPath = indexPath
        self.offset = offset
        self.listView = listView
    }
}

public extension Context {
    func dequeueReusableCell<CustomCell: UIView>(
        withCellClass cellClass: CustomCell.Type,
        identifier: String = "",
        configuration: (CustomCell) -> Void = { _ in }
    ) -> List.Cell {
        return listView.dequeueReusableCell(
            withCellClass: cellClass,
            identifier: identifier,
            indexPath: listIndexPath,
            configuration: configuration
        )
    }

    func dequeueReusableCell<CustomCell: UIView>(
        withCellClass cellClass: CustomCell.Type,
        storyBoardIdentifier: String,
        indexPath: IndexPath,
        configuration: (CustomCell) -> Void = { _ in }
    ) -> List.Cell {
        return listView.dequeueReusableCell(
            withCellClass: cellClass,
            storyBoardIdentifier: storyBoardIdentifier,
            indexPath: indexPath,
            configuration: configuration
        )
    }
    
    func dequeueReusableCell<CustomCell: UIView>(
        withCellClass cellClass: CustomCell.Type,
        withNibName nibName: String,
        bundle: Bundle? = nil,
        configuration: (CustomCell) -> Void = { _ in }
      ) -> List.Cell {
        return listView.dequeueReusableCell(
            withCellClass: cellClass,
            withNibName: nibName,
            bundle: bundle,
            indexPath: listIndexPath,
            configuration: configuration
        )
    }
    
    func dequeueReusableSupplementaryView<CustomSupplementaryView: UIView>(
        type: SupplementaryViewType,
        withSupplementaryClass supplementaryClass: CustomSupplementaryView.Type,
        identifier: String = "",
        configuration: (CustomSupplementaryView) -> Void = { _ in }
    ) -> List.SupplementaryView {
        return listView.dequeueReusableSupplementaryView(
            type: type,
            withSupplementaryClass: supplementaryClass,
            identifier: identifier,
            indexPath: listIndexPath,
            configuration: configuration
        )
    }
    
    func dequeueReusableSupplementaryView<CustomSupplementaryView: UIView>(
        type: SupplementaryViewType,
        withSupplementaryClass cellClass: CustomSupplementaryView.Type,
        nibName: String,
        bundle: Bundle? = nil,
        configuration: (CustomSupplementaryView) -> Void = { _ in }
    ) -> List.SupplementaryView {
        return listView.dequeueReusableSupplementaryView(
            type: type,
            withSupplementaryClass: cellClass,
            nibName: nibName,
            bundle: bundle,
            indexPath: listIndexPath,
            configuration: configuration
        )
    }
}
