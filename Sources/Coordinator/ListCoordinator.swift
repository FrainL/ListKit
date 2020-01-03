//
//  ListCoordinator.swift
//  ListKit
//
//  Created by Frain on 2019/11/25.
//

final class ListContext {
    weak var listView: ListView?
    var sectionOffset: Int
    var itemOffset: Int
    
    init(listView: ListView?, sectionOffset: Int, itemOffset: Int) {
        self.listView = listView
        self.sectionOffset = sectionOffset
        self.itemOffset = itemOffset
    }
}

public class ListCoordinator<SourceBase: DataSource>: ItemTypedCoorinator<SourceBase.Item> {
    typealias Item = SourceBase.Item
    
    weak var storage: CoordinatorStorage<SourceBase>?
    
    var nestedAdapterItemUpdate = [AnyHashable: (Item) -> Void]()
    var cacheForItem = [[Any]]()
    var cacheFromItem: ((Item) -> Any)?
    var listContexts = [ObjectIdentifier: ListContext]()
    var source: SourceBase.Source { fatalError() }
    var didSetup = false
    
    override var anySource: Any { source }
    
    override func setup(
        listView: ListView,
        key: ObjectIdentifier,
        sectionOffset: Int = 0,
        itemOffset: Int = 0
    ) {
        if let context = listContexts[key] {
            context.sectionOffset = sectionOffset
            context.itemOffset = itemOffset
            return
        }
        
        let context = ListContext(
            listView: listView,
            sectionOffset: sectionOffset,
            itemOffset: itemOffset
        )
        listContexts[key] = context
        if !didSetup { setup() }
    }
    
    func offset(for object: AnyObject) -> (Int, Int) {
        guard let context = listContexts[ObjectIdentifier(object)] else { return (0, 0) }
        return (context.sectionOffset, context.itemOffset)
    }
    
    func setup() {
        didSetup = true
    }
    
    func update(from coordinator: ListCoordinator<SourceBase>) {
        
    }
    
    func update(
        to sourceBase: SourceBase,
        animated: Bool,
        completion: ((ListView, Bool) -> Void)?
    ) {
        
    }
    
    func reload(
        to sourceBase: SourceBase,
        animated: Bool,
        completion: ((ListView, Bool) -> Void)?
    ) {
        
    }
    
    func reloadData(
        to sourceBase: SourceBase,
        animated: Bool,
        completion: ((ListView, Bool) -> Void)?
    ) {
        
    }
    
    func removeCurrent(animated: Bool, completion: ((ListView, Bool) -> Void)?) {
        
    }
    
    func set<Object: AnyObject, Input, Output>(
        _ keyPath: ReferenceWritableKeyPath<BaseCoordinator, Delegate<Object, Input, Output>>,
        _ closure: @escaping (ListCoordinator<SourceBase>, Object, Input) -> Output
    ) {
        self[keyPath: keyPath].closure = { [unowned self] in closure(self, $0, $1) }
        let delegate = self[keyPath: keyPath]
        switch delegate.index {
        case .none: selectorSets { $0.value.remove(delegate.selector) }
        case .index: selectorSets { $0.withIndex.remove(delegate.selector) }
        case .indexPath: selectorSets { $0.withIndexPath.remove(delegate.selector) }
        }
    }

    func set<Object: AnyObject, Input>(
        _ keyPath: ReferenceWritableKeyPath<BaseCoordinator, Delegate<Object, Input, Void>>,
        _ closure: @escaping (ListCoordinator<SourceBase>, Object, Input) -> Void
    ) {
        self[keyPath: keyPath].closure = { [unowned self] in closure(self, $0, $1) }
        let delegate = self[keyPath: keyPath]
        selectorSets { $0.void.remove(delegate.selector) }
    }
    
    func selectorSets(applying: (inout SelectorSets) -> Void) {
        applying(&selectorSets)
    }
    
    init(storage: CoordinatorStorage<SourceBase>? = nil) {
        super.init()
        
        self.storage = storage
    }
    
    init(_ sourceBase: SourceBase, storage: CoordinatorStorage<SourceBase>? = nil) {
        super.init()
        
        self.storage = storage
        
        selfType = ObjectIdentifier(SourceBase.self)
        itemType = ObjectIdentifier(SourceBase.Item.self)
    }
}
