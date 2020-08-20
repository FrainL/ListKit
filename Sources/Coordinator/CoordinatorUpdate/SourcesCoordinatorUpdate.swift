//
//  SourcesCoordinatorUpdate.swift
//  ListKit
//
//  Created by Frain on 2020/7/12.
//

import Foundation

extension CoordinatorUpdate {
    final class SourcesChange<SourceBase: DataSource, Source: RangeReplaceableCollection>:
        Change<SourceElement<Source.Element>>
    where
        SourceBase.SourceBase == SourceBase,
        Source.Element: DataSource,
        Source.Element.SourceBase.Item == SourceBase.Item
    {
        var update = Cache(value: nil as CoordinatorUpdate?)
        
        func update(_ isSource: Bool, _ id: ObjectIdentifier?) -> CoordinatorUpdate {
            self.update[id] ?? {
                let update = value.coordinator.update(isSource ? .remove : .insert)
                self.update[nil] = update
                return update
            }()
        }
    }
    
    enum SourcesDifferenceChange<SourceBase: DataSource, Source: RangeReplaceableCollection>
    where
        SourceBase.SourceBase == SourceBase,
        Source.Element: DataSource,
        Source.Element.SourceBase.Item == SourceBase.Item
    {
        case update(Mapping<Int>, Mapping<SourceElement<Source.Element>>, CoordinatorUpdate)
        case change(SourcesChange<SourceBase, Source>, isSource: Bool)
    }
}

final class SourcesCoordinatorUpdate<SourceBase: DataSource, Source: RangeReplaceableCollection>:
    DiffableCoordinatgorUpdate<
        SourceBase,
        Source,
        SourceElement<Source.Element>,
        CoordinatorUpdate.SourcesChange<SourceBase, Source>,
        CoordinatorUpdate.SourcesDifferenceChange<SourceBase, Source>
    >
where
    SourceBase.SourceBase == SourceBase,
    Source.Element: DataSource,
    Source.Element.SourceBase.Item == SourceBase.Item
{
    typealias Change = SourcesChange<SourceBase, Source>
    typealias DifferenceChange = SourcesDifferenceChange<SourceBase, Source>
    
    typealias Subsource = SourcesCoordinator<SourceBase, Source>.Subsource
    typealias Subupdate = CoordinatorUpdate
    typealias Subcoordinator = ListCoordinator<Element.SourceBase>
    
    weak var coordinator: SourcesCoordinator<SourceBase, Source>?
    
    var subsourceType: SourcesCoordinator<SourceBase, Source>.SubsourceType
    var indices: Mapping<Indices>
    lazy var operations = [() -> Void]()
    lazy var subupdates = [Int: CoordinatorUpdate]()
    
    lazy var offsetForOrder = Cache(value: [Order: [ObjectIdentifier: Int]]())
    
    override var diffable: Bool { true }
    override var equaltable: Bool { true }
    override var identifiable: Bool { true }
    override var moveAndReloadable: Bool { true }
    override var shouldConsiderUpdate: Bool { super.shouldConsiderUpdate || !subupdates.isEmpty }
    
    init(
        coordinator: SourcesCoordinator<SourceBase, Source>,
        update: ListUpdate<SourceBase>,
        values: Values,
        sources: Sources,
        indices: Mapping<Indices>,
        keepSectionIfEmpty: Mapping<Bool>,
        isSectioned: Bool
    ) {
        self.subsourceType = coordinator.subsourceType
        self.coordinator = coordinator
        self.indices = indices
        super.init(coordinator, update: update, values, sources, keepSectionIfEmpty)
        self.isSectioned = isSectioned
    }
    
    override func getSourceCount() -> Int { indices.source.count }
    override func getTargetCount() -> Int { indices.target.count }
    
    override func toCount(_ value: Subsource) -> Int { value.count }
    override func toValue(_ element: Element) -> Subsource {
        let coordinator = element.listCoordinator
        let context = coordinator.context()
        let count = isSectioned ? context.numbersOfSections() : context.numbersOfItems(in: 0)
        return .init(element: .element(element), context: context, offset: 0, count: count)
    }
    
    override func toSource(_ values: ContiguousArray<Subsource>) -> SourceBase.Source? {
        guard case let .fromSourceBase(_, map) = subsourceType else { return nil }
        return map(.init(values.flatMap { subsource -> ContiguousArray<Element> in
            switch subsource.element {
            case let .items(_, items): return items()
            case let .element(element): return [element]
            }
        }))
    }
    
    override func updateIndicesAfterUpdateIfNeeded() {
        var offset = 0
        values.target = values.target.mapContiguous { value in
            defer { offset += value.count }
            return .init(
                element: value.element,
                context: value.context,
                offset: offset,
                count: value.count
            )
        }
        indices.target = SourcesCoordinator<SourceBase, Source>.toIndices(values.target)
    }
    
    override func append(change: Change, isSource: Bool, to changes: inout Differences) {
        changes[keyPath: path(isSource)].append(.change(.change(change, isSource: isSource)))
        guard change.associated[nil] == nil else { return }
        changes[keyPath: path(!isSource)].append(.change(.change(change, isSource: isSource)))
    }
    
    override func append(change: DifferenceChange, into values: inout ContiguousArray<Subsource>) {
        switch change {
        case let .change(change, isSource: isSource) where !isSource:
            values.append(change.value)
        case let .update(_, value, update):
            values.append(.init(
                element: value.target.element,
                context: value.target.context,
                offset: 0,
                count: update.targetCount
            ))
        default: break
        }
    }
    
    override func canConfigUpdateAt(index: Mapping<Int>, last: Mapping<Int>, into changes: inout Differences) -> Bool {
        if super.canConfigUpdateAt(index: index, last: last, into: &changes) { return true }
        guard let update = subupdates[index.source] else { return false }
        appendUnchanged(index: index, last: last, to: &changes)
        let value: Mapping = (values.source[index.source], values.source[index.target])
        changes.source.append(.change(.update(index, value, update)))
        changes.target.append(.change(.update(index, value, update)))
        return true
    }
    
    override func diffAppend(from: Mapping<Int>, to: Mapping<Int>, to changes: inout Differences) {
        for (s, t) in zip(from.source..<to.source, from.target..<to.target) {
            let source = values.source[s], target = values.target[t]
            let way = differ.map { ListUpdateWay.diff($0) }
            let update = target.coordinator.update(from: source.coordinator, updateWay: way)
            changes.source.append(.change(.update((s, t), (source, target), update)))
            changes.target.append(.change(.update((s, t), (source, target), update)))
        }
    }
    
    override func inferringMoves(context: ContextAndID? = nil) {
        super.inferringMoves(context: context)
        let context = context ?? defaultContext
        changes.source.forEach {
            switch $0 {
            case let .change(.change(change, isSource: isSource)) where change[nil] == nil:
                change.update(isSource, context.id).inferringMoves(context: context)
            case let .change(.update(_, _, update)):
                update.inferringMoves(context: context)
            default:
                break
            }
        }
    }
    
    override func updateData(_ isSource: Bool) {
        super.updateData(isSource)
        guard let coordinator = coordinator else { return }
        if hasBatchUpdate { updateIndicesAfterUpdateIfNeeded() }
        coordinator.subsources = coordinator.settingIndex(isSource ? values.source : values.target)
        coordinator.indices = isSource ? indices.source : indices.target
        if !isSource { coordinator.resetDelegates() }
    }
    
    override func isEqual(lhs: Subsource, rhs: Subsource) -> Bool {
        let related = lhs.context
        switch (lhs.element, rhs.element) {
        case let (.element(lhs), .element(rhs)):
            return related.coordinator.equal(lhs: lhs.sourceBase, rhs: rhs.sourceBase)
        case let (.items(lhs, _), .items(rhs, _)):
            return lhs == rhs
        default:
            return false
        }
    }
    
    override func identifier(for value: Subsource) -> AnyHashable {
        switch value.element {
        case .element(let element):
            return HashCombiner(0, value.coordinator.identifier(for: element.sourceBase))
        case .items(let id, _):
            return HashCombiner(1, id)
        }
    }
    
    override func isDiffEqual(lhs: Subsource, rhs: Subsource) -> Bool {
        guard identifier(for: lhs) == identifier(for: rhs) else { return false }
        return isEqual(lhs: lhs, rhs: rhs)
    }
    
    override func configChangeAssociated(
        for mapping: Mapping<Change>,
        context: ContextAndID?
    ) {
        let source = mapping.source.value.coordinator
        let target = mapping.target.value.coordinator
        let update = target.update(from: source, updateWay: .diff(differ))
        mapping.source.update[context?.id] = update
        mapping.target.update[context?.id] = update
    }
    
    override func generateSourceUpdate(
        order: Order,
        context: UpdateContext<Int>? = nil
    ) -> UpdateSource<BatchUpdates.ListSource> {
        guard isSectioned else { return super.generateSourceUpdate(order: order, context: context) }
        return sourceUpdate(order, in: context, \.section, Subupdate.generateSourceUpdate)
    }
    
    override func generateTargetUpdate(
        order: Order,
        context: UpdateContext<Offset<Int>>? = nil
    ) -> UpdateTarget<BatchUpdates.ListTarget> {
        guard isSectioned else { return super.generateTargetUpdate(order: order, context: context) }
        return targetUpdate(order, in: context, \.section, Subupdate.generateTargetUpdate)
    }
    
    override func generateSourceItemUpdate(
        order: Order,
        context: UpdateContext<IndexPath>? = nil
    ) -> UpdateSource<BatchUpdates.ItemSource> {
        sourceUpdate(order, in: context, \.self, Subupdate.generateSourceItemUpdate)
    }
    
    override func generateTargetItemUpdate(
        order: Order,
        context: UpdateContext<Offset<IndexPath>>? = nil
    ) -> UpdateTarget<BatchUpdates.ItemTarget> {
        targetUpdate(order, in: context, \.self, Subupdate.generateTargetItemUpdate)
    }
}

extension SourcesCoordinatorUpdate {
    func subsource<Subsource: UpdatableDataSource>(
        _ source: Subsource,
        update: ListUpdate<Subsource.SourceBase>,
        animated: Bool? = nil,
        completion: ((ListView, Bool) -> Void)? = nil
    ) {
        operations.append { source.perform(update, animated: animated, completion: completion) }
    }
    
    func add(subupdate: CoordinatorUpdate, at index: Int) {
        if subupdate.isRemove {
            remove(at: index)
        } else {
            subupdates[index] = subupdate
        }
    }
    
    func sourceUpdate<Collection: UpdateIndexCollection, Result: BatchUpdate, O>(
        _ order: Order,
        in context: UpdateContext<O>?,
        _ keyPath: WritableKeyPath<Result, BatchUpdates.Source<Collection>>,
        _ toSubUpdate: (Subupdate) -> (Order, UpdateContext<O>?) -> UpdateSource<Result>
    ) -> UpdateSource<Result> where Collection.Element == O {
        if notUpdate(order, context) { return (targetCount, nil) }
        var count = 0, offsets = [ObjectIdentifier: Int](), result = Result()
        var offset: O { .init(context?.offset, offset: count) }
        
        defer { offsetForOrder[context?.id][order] = offsets }
        
        func add(value: Subsource) {
            if value.count == 0 { return }
            count += value.count
        }
        
        func add(_ update: Subupdate, isMoved: Bool) {
            let subcontext = toContext(context, isMoved, or: .zero) { $0.offseted(count) }
            let (subcount, subupdate) = toSubUpdate(update)(order, subcontext)
            offsets[ObjectIdentifier(update)] = count
            count += subcount
            subupdate.map { result.add($0) }
            Log.log("\(update)\(subupdate.isEmpty ? " none" : "")")
            Log.log(subupdate.isEmpty ? nil : subupdate?.description)
        }
        
        func reload(from value: Subsource, to other: Subsource) {
            let (diff, minValue) = (value.count - other.count, min(value.count, other.count))
            defer { count += value.count }
            if minValue > 0 {
                result[keyPath: keyPath].add(\.reloads, offset, offset.offseted(minValue))
            }
            if diff > 0 {
                let upper = offset.offseted(value.count)
                result[keyPath: keyPath].add(\.deletes, upper.offseted(-diff), upper)
            }
        }
        
        func configChange(_ change: Change) {
            configCoordinatorChange(
                change,
                context: context,
                enumrateChange: { change in
                    context.map { change.offsets[$0.id] = (offset.section, offset.item) }
                },
                deleteOrInsert: { change in
                    add(change.update(true, context?.id), isMoved: false)
                },
                reload: { (change, associated) in
                    if isMain(order) {
                        reload(from: change.value, to: associated.value)
                    } else {
                        add(value: associated.value)
                    }
                },
                move: { change, associated, isReload in
                    guard isReload else {
                        let moved = isMain(order), update = change.update(true, context?.id)
                        add(update, isMoved: moved)
                        return
                    }
                    if isMain(order) {
                        updateMaxIfNeeded(order, context, isSectioned)
                        offsets[ObjectIdentifier(associated)] = count
                        add(value: change.value)
                        if change.value.count == 0 { return }
                        result[keyPath: keyPath].move(offset, offset.offseted(change.value.count))
                    } else if isExtra(order) {
                        reload(from: change.value, to: associated.value)
                    } else {
                        add(value: associated.value)
                    }
                }
            )
        }
        
        func config(value: Difference) {
            switch value {
            case let .change(.change(change, isSource: isSource)):
                if isSource {
                    configChange(change)
                } else {
                    add(change.update(false, context?.id), isMoved: false)
                }
            case let .change(.update(_, value, update)):
                switch update.changeType {
                case .none where value.source.count != value.target.count && isMain(order),
                     .reload where isMain(order):
                    reload(from: value.source, to: value.target)
                default:
                    add(update, isMoved: false)
                }
            case let .unchanged(from: from, to: to):
                guard context?.isMoved != true else { fatalError("TODO") }
                (from.source..<to.source).forEach { add(value: values.source[$0]) }
            }
        }
        
        if isMain(order) {
            changes.source.forEach(config(value:))
        } else {
            changes.target.forEach(config(value:))
        }
        
        return (count, result)
    }
    
    func targetUpdate<Collection: UpdateIndexCollection, Result: BatchUpdate, O>(
        _ order: Order,
        in context: UpdateContext<Offset<O>>?,
        _ keyPath: WritableKeyPath<Result, BatchUpdates.Target<Collection>>,
        _ toSubresult: (Subupdate) -> (Order, UpdateContext<Offset<O>>?) -> UpdateTarget<Result>
    ) -> UpdateTarget<Result> where Collection.Element == O {
        if notUpdate(order, context) { return (toIndices(indices.target, context), nil, nil) }
        var subsources = ContiguousArray<Subsource>(capacity: values.target.count)
        var indices = Indices(capacity: self.indices.source.count)
        var result = Result(), change: (() -> Void)?
        var offset: O { .init(context?.offset.offset.target, offset: indices.count) }
        var index: Int { subsources.count }
        let offsets = offsetForOrder[context?.id][order]!
        
        func add(value: Subsource) {
            let count = indices.count
            indices.append(repeatElement: (index, false), count: value.count)
            subsources.append(value.setting(offset: count))
        }
        
        func add(value: Subsource, update: Subupdate, isMoved: Bool, isSource: Bool = false) {
            guard let o = offsets[ObjectIdentifier(update)] else { return }
            let subcontext = toContext(context, isMoved, or: (0, (.zero, .zero))) {
                (index, ($0.offset.source.offseted(o), $0.offset.source.offseted(indices.count)))
            }
            let (subindices, subupdate, subchange) = toSubresult(update)(order, subcontext)
            subupdate.map { result.add($0) }
            change = change + subchange
            Log.log("\(value)\(subupdate.isEmpty ? " none" : "")")
            Log.log(subupdate.isEmpty ? nil : subupdate?.description)
            updateMaxIfNeeded(update, context, subcontext)
            if isSource, !hasNext(order, context) { return }
            let count = indices.count
            indices.append(contentsOf: subindices)
            subsources.append(value.setting(offset: count, count: subindices.count))
        }
        
        func reload(from other: Subsource, to value: Subsource) {
            let diff = value.count - other.count, minValue = min(other.count, value.count)
            if minValue != 0 {
                result[keyPath: keyPath].reload(offset, offset.offseted(minValue))
            }
            if diff > 0 {
                let upper = offset.offseted(value.count)
                result[keyPath: keyPath].add(\.inserts, upper.offseted(-diff), upper)
            }
            let count = indices.count
            indices.append(repeatElement: (index, false), count: value.count)
            subsources.append(value.setting(offset: count))
        }
        
        func configChange(_ change: Change) {
            configCoordinatorChange(
                change,
                context: context,
                enumrateChange: { change in
                    guard let ((_, (_, target)), _, id) = context else { return }
                    change.offsets[id] = (target.section, target.item)
                },
                deleteOrInsert: { change in
                    let update = change.update(false, context?.id)
                    add(value: change.value, update: update, isMoved: false)
                },
                reload: { change, associated in
                    if isMain(order) {
                        reload(from: associated.value, to: change.value)
                    } else {
                        add(value: change.value)
                    }
                },
                move: { change, associated, isReload in
                    guard isReload else {
                        let moved = isMain(order), update = change.update(false, context?.id)
                        add(value: change.value, update: update, isMoved: moved)
                        return
                    }
                    if isMain(order) {
                        add(value: associated.value)
                        let count = associated.value.count
                        guard count != 0, let o = offsets[ObjectIdentifier(change)] else { return }
                        let source = O(context?.offset.offset.source, offset: o)
                        result[keyPath: keyPath].move(
                            (source, offset),
                            (source.offseted(count), offset.offseted(count))
                        )
                    } else if isExtra(order) {
                        reload(from: associated.value, to: change.value)
                    } else {
                        add(value: change.value)
                    }
                }
            )
        }
        
        for value in changes.target {
            switch value {
            case let .change(.change(change, isSource: isSource)):
                if isSource {
                    let update = change.update(false, context?.id)
                    add(value: change.value, update: update, isMoved: false, isSource: true)
                } else {
                    configChange(change)
                }
            case let .change(.update(_, value, update)):
                switch update.changeType {
                case .none where value.source.count != value.target.count && isMain(order),
                     .reload where isMain(order):
                    reload(from: value.source, to: value.target)
                case _ where update.changeType.shouldGetSubupdate:
                    add(value: value.target, update: update, isMoved: false)
                default:
                    add(value: value.target)
                }
            case let .unchanged(from: from, to: to):
                guard context?.isMoved != true else { fatalError("TODO") }
                (from.target..<to.target).forEach { add(value: values.target[$0]) }
            }
        }
        
        let source = toSource(subsources)
        change = change + { [unowned self] in
            guard let coordinator = self.coordinator else { return }
            Log.log("\(self) set indices: \(indices.map { $0 })")
            Log.log("\(self) set subsources: \(subsources.map { $0 })")
            coordinator.subsources = coordinator.settingIndex(subsources)
            coordinator.indices = indices
            coordinator.resetDelegates()
            coordinator.source = source
        }
        
        return (toIndices(indices, context), result, change)
    }
}
