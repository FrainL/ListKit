//
//  SourcesCoordinator.swift
//  ListKit
//
//  Created by Frain on 2019/11/28.
//

final class SourcesCoordinator<SourceBase: DataSource>: SourceStoredListCoordinator<SourceBase>
where
    SourceBase.Source: RangeReplaceableCollection,
    SourceBase.Source.Element: DataSource,
    SourceBase.Source.Element.SourceBase.Item == SourceBase.Item
{
    typealias Subcoordinator = ListCoordinator<SourceBase.Source.Element.SourceBase>
    
    var subsources = [SourceBase.Source.Element]()
    var subcoordinators = [Subcoordinator]()
    var offsets = [Path]()
    var isAnyType = Item.self == Any.self
    
    lazy var selfSelectorSets = initialSelectorSets()
    var others = SelectorSets()
    
    override var isEmpty: Bool { sourceIndices.isEmpty }
    
    override func item<Path: PathConvertible>(at path: Path) -> Item {
        let indexAt = sourceIndices.index(of: path)
        let offset = offsets[indexAt]
        let subcoordinator = subcoordinators[indexAt]
        return subcoordinator.item(at: path - offset)
    }
    
    override func anyItemSources<Source: DataSource>(source: Source) -> AnyItemSources {
        .inSource(.init(source: source, coordinator: self) {
            zip(self.subsources, self.subcoordinators).map { (source, coordinator) in
                coordinator.anyItemSources(source: source)
            }
        })
    }
    
    override func anySectionSources<Source: DataSource>(source: Source) -> AnySectionSources {
        .inSource(.init(source: source, coordinator: self) {
            self.subsectionSources(
                subcoordinators: self.subcoordinators,
                getter: BaseCoordinator.anySectionSources
            )
        })
    }
    
    override func anySourceUpdate(to sources: [AnyDiffableSourceValue]) {
        var anySubsources = [SourceBase.Source.Element]()
        var coordinators = [Subcoordinator]()
        for source in sources {
            anySubsources.append(source.value() as! SourceBase.Source.Element)
            coordinators.append(source.coordinator as! Subcoordinator)
        }
        subsources = anySubsources
        subcoordinators = coordinators
        resetAndConfigIndicesAndOffsets()
    }
    
    override func itemSources<Source: DataSource>(
        source: Source
    ) -> ItemSource where Source.SourceBase.Item == Item {
        .inSource(.init(source: source, coordinator: self) {
            zip(self.subsources, self.subcoordinators).map { (source, coordinator) in
                coordinator.itemSources(source: source)
            }
        })
    }
    
    override func sectionSources<Source: DataSource>(source: Source) -> SectionSource {
        .inSource(.init(source: source, coordinator: self) {
            self.subsectionSources(
                subcoordinators: self.subcoordinators,
                getter: ItemTypedCoorinator<Item>.sectionSources
            )
        })
    }
    
    override func sourceUpdate(to sources: [DiffableSourceValue]) {
        var anySubsources = [SourceBase.Source.Element]()
        var coordinators = [Subcoordinator]()
        for source in sources {
            anySubsources.append(source.value() as! SourceBase.Source.Element)
            coordinators.append(source.coordinator as! Subcoordinator)
        }
        subsources = anySubsources
        subcoordinators = coordinators
        resetAndConfigIndicesAndOffsets()
    }
    
    override func setup(
        listView: ListView,
        key: ObjectIdentifier,
        sectionOffset: Int = 0,
        itemOffset: Int = 0
    ) {
        if let context = listContexts[key] {
            context.sectionOffset = sectionOffset
            context.itemOffset = itemOffset
            configSubcoordinator(for: [(key, context)])
            return
        }
        
        let context = ListContext(
            listView: listView,
            sectionOffset: sectionOffset,
            itemOffset: itemOffset
        )
        listContexts[key] = context
        if !didSetup {
            setupCoordinators()
            rangeReplacable = true
            let hasSectioned = configSubcoordinator(
                for: [(key, context)],
                isReset: true
            )
            setupSelectorSets()
            sourceType = (selectorSets.hasIndex || hasSectioned) ? .section : .cell
            didSetup = true
        } else {
            configSubcoordinator(for: [(key, context)], isReset: false)
        }
    }
    
    override func selectorSets(applying: (inout SelectorSets) -> Void) {
        super.selectorSets(applying: applying)
        applying(&selfSelectorSets)
    }
    
    override func apply<Object: AnyObject, Input, Output>(
        _ keyPath: KeyPath<BaseCoordinator, Delegate<Object, Input, Output>>,
        object: Object,
        with input: Input
    ) -> Output {
        let closure = self[keyPath: keyPath]
        let coordinator = subcoordinator(for: closure, object: object, with: input)
        return coordinator?.apply(keyPath, object: object, with: input)
            ?? super.apply(keyPath, object: object, with: input)
    }
    
    override func apply<Object: AnyObject, Input>(
        _ keyPath: KeyPath<BaseCoordinator, Delegate<Object, Input, Void>>,
        object: Object,
        with input: Input
    ) {
        let closure = self[keyPath: keyPath]
        let coordinator = subcoordinator(for: closure, object: object, with: input)
        coordinator?.apply(keyPath, object: object, with: input)
        super.apply(keyPath, object: object, with: input)
    }
    
    func setupSelectorSets() {
        others = initialSelectorSets(withoutIndex: true)
        for coordinator in subcoordinators where coordinator.isEmpty == false {
            others.void.formIntersection(coordinator.selectorSets.void)
            others.withIndex.formUnion(coordinator.selectorSets.withIndex)
            others.withIndexPath.formUnion(coordinator.selectorSets.withIndexPath)
            others.hasIndex = others.hasIndex || coordinator.selectorSets.hasIndex
        }
        selectorSets = SelectorSets(merging: selfSelectorSets, others)
    }
    
    func subcoordinator<Object: AnyObject, Input, Output>(
        for delegate: Delegate<Object, Input, Output>,
        object: Object,
        with input: Input
    ) -> BaseCoordinator? {
        guard let index = delegate.index else { return nil }
        let (sectionOffset, itemOffset) = offset(for: object)
        let offset: Int
        switch index {
        case let .index(keyPath):
            let section = input[keyPath: keyPath]
            guard let index = sourceIndices.index(of: section - sectionOffset) else {
                return nil
            }
            offset = index
        case let .indexPath(keyPath):
            let path = input[keyPath: keyPath]
            let index = Path(section: path.section - sectionOffset, item: path.item - itemOffset)
            offset = sourceIndices.index(of: index)
        }
        let coordinator = subcoordinators[offset]
        return coordinator.selectorSets.contains(delegate.selector) ? nil : coordinator
    }
    
    func resetAndConfigIndicesAndOffsets() {
        offsets.removeAll(keepingCapacity: true)
        sourceIndices.removeAll(keepingCapacity: true)
        configSubcoordinator(for: listContexts, isReset: true)
    }
    
    func setupCoordinators() {
        for subsource in source {
            subsources.append(subsource)
            subcoordinators.append(subsource.makeListCoordinator())
        }
    }
    
    @discardableResult
    func configSubcoordinator<C: Collection>(
        for collection: C,
        isReset: Bool = true
    ) -> Bool where C.Element == (key: ObjectIdentifier, value: ListContext) {
        var hasSectioned = false
        if isReset {
            var offset = Path()
            for coordinator in subcoordinators {
                collection.forEach { setCoordinator(coordinator, context: $0, offset: offset) }
                appendCoordinator(coordinator, offset: &offset, hasSection: &hasSectioned)
            }
        } else {
            for (subcoordinator, offset) in zip(subcoordinators, offsets) {
                collection.forEach { setCoordinator(subcoordinator, context: $0, offset: offset) }
            }
        }
        
        return hasSectioned
    }
    
    func appendCoordinator(
        _ subcoordinator: BaseCoordinator,
        offset: inout Path,
        hasSection: inout Bool
    ) {
        offsets.append(offset)
        switch (subcoordinator.sourceType, sourceIndices.last) {
        case (.section, _):
            let sections = subcoordinator.sourceIndices.sections(with: offsets.count - 1)
            guard !sections.isEmpty else { break }
            hasSection = true
            sourceIndices.append(contentsOf: sections)
            offset = Path(section: sourceIndices.count)
        case (.cell, .cell(var cells)?):
            let cellCounts = subcoordinator.numbersOfItems(in: 0)
            guard cellCounts != 0 else { break }
            cells.append(contentsOf: repeatElement(offsets.count - 1, count: cellCounts))
            offset.item = cells.count
            sourceIndices[sourceIndices.lastIndex] = .cell(indices: cells)
        case (.cell, _):
            let cellCounts = subcoordinator.numbersOfItems(in: 0)
            guard cellCounts != 0 else { break }
            let indices = Array(repeating: offset.section, count: cellCounts)
            sourceIndices.append(.cell(indices: indices))
            offset = Path(section: sourceIndices.count)
        }
    }
    
    func setCoordinator(
        _ subcoordinator: BaseCoordinator,
        context: (ObjectIdentifier, ListContext),
        offset: Path
    ) {
        guard let listView = context.1.listView else { return }
        subcoordinator.setup(
            listView: listView,
            key: context.0,
            sectionOffset: offset.section + context.1.sectionOffset,
            itemOffset: offset.item + context.1.itemOffset
        )
    }
    
    func subsectionSources<C: BaseCoordinator, V, D>(
        subcoordinators: [C],
        getter: (C) -> (SourceBase.Source.Element) -> SectionSourceValue<C, V, D>
    ) -> [SectionSourceValue<C, V, D>] {
        var results = [SourceValue<Other<C, V, D>, C, V, D>]()
        for (source, coordinator) in zip(subsources, subcoordinators) {
            let sectionSource = getter(coordinator)(source)
            switch (sectionSource, results.last) {
            case let (.other(other), .other(others))
                where other.type == .cellContainer && others.type == .cellContainer:
                let diffables = others.diffables() + other.diffables()
                let resultOther = Other(type: .cellContainer, diffables: { diffables })
                results[results.lastIndex] = .other(resultOther)
            default:
                results.append(getter(coordinator)(source))
            }
        }
        return results
    }
}

fileprivate extension BidirectionalCollection {
    var lastIndex: Index {
        return Swift.max(index(before: endIndex), startIndex)
    }
}

fileprivate extension Collection where Element == SourceIndices {
    func sections(with offset: Int) -> [SourceIndices] {
        map { .section(index: offset, count: $0.count) }
    }
}
