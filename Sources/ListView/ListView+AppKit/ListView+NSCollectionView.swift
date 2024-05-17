//
//  ListView+NSCollectionView.swift
//  ListKit
//
//  Created by Frain on 2019/12/9.
//

#if os(macOS)
import AppKit

public typealias CollectionView = NSCollectionView

extension NSCollectionView: NSListView, SetuptableListView {
    public typealias Cell = NSCollectionViewItem
    public typealias Animation = Bool

    func setup(with listDelegate: Delegate) {
        dataSource = listDelegate
        delegate = listDelegate
    }

    func isDelegate(_ listDelegate: Delegate) -> Bool {
        dataSource === listDelegate && delegate === listDelegate
    }
}

public extension NSCollectionView {
    var defaultAnimation: Bool {
        get { Associator.getValue(key: &Self.listViewDefaultAnimationKey, from: self) ?? true }
        set { Associator.set(value: newValue, key: &Self.listViewDefaultAnimationKey, to: self) }
    }

    func adapted<Adapter: ListAdapter>(
        by listAdapter: Adapter,
        animated: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) where Adapter.View: NSCollectionView {
        listDelegate.setCoordinator(
            context: listAdapter.listCoordinatorContext,
            animated: animated,
            completion: completion
        )
    }

    func resetDelegates(toNil: Bool) {
        let temp = (dataSource, delegate)
        (dataSource, delegate) = (nil, nil)
        if toNil { return }
        (dataSource, delegate) = temp
    }

    func reloadSynchronously(animated: Bool = true) {
        if animated {
            reloadData()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            reloadData()
            CATransaction.commit()
        }
//        if window != nil {
//            layout()
//        }
    }

    func perform(_ update: () -> Void, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if animated {
            performBatchUpdates(update, completionHandler: completion)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            performBatchUpdates(update, completionHandler: completion)
            CATransaction.commit()
        }
    }

    func insertItems(at indexPaths: [IndexPath]) {
        insertItems(at: Set(indexPaths))
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        deleteItems(at: Set(indexPaths))
    }

    func reloadItems(at indexPaths: [IndexPath]) {
        reloadItems(at: Set(indexPaths))
    }

    func register(supplementaryViewType: SupplementaryViewType, _ supplementaryClass: AnyClass?, forSupplementaryViewOfKind kind: SupplementaryElementKind, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
        register(supplementaryClass, forSupplementaryViewOfKind: kind, withIdentifier: identifier)
    }

    func register(supplementaryViewType: SupplementaryViewType, _ nib: NSNib?, forSupplementaryViewOfKind kind: SupplementaryElementKind, withIdentifier identifier: NSUserInterfaceItemIdentifier) {
        register(nib, forSupplementaryViewOfKind: kind, withIdentifier: identifier)
    }

    func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> NSCollectionViewItem {
        makeItem(withIdentifier: .init(identifier), for: indexPath)
    }

}

public extension NSCollectionView {
    enum SupplementaryViewType {
        case header
        case footer
        case custom(String)

        public init(rawValue: String) {
            switch rawValue {
            case NSCollectionView.elementKindSectionHeader: self = .header
            case NSCollectionView.elementKindSectionFooter: self = .footer
            default: self = .custom(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .header: return NSCollectionView.elementKindSectionHeader
            case .footer: return NSCollectionView.elementKindSectionFooter
            case .custom(let string): return string
            }
        }
    }
}

extension NSCollectionView {
    static var listViewDefaultAnimationKey: Void?

    func kind(for kind: SupplementaryViewType) -> String {
        switch kind {
        case .header: return NSCollectionView.elementKindSectionHeader
        case .footer: return NSCollectionView.elementKindSectionFooter
        case .custom(let kind): return kind
        }
    }
}

extension Bool: ListViewAnimationOption {
    public init(animated: Bool) {
        self = animated
    }
}


#endif
