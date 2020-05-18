//
//  SectionsCoordinator.swift
//  ListKit
//
//  Created by Frain on 2019/12/3.
//

import Foundation

class SectionsCoordinator<SourceBase: DataSource>: ListCoordinator<SourceBase>
where
    SourceBase.SourceBase == SourceBase,
    SourceBase.Source: Collection,
    SourceBase.Source.Element: Collection,
    SourceBase.Source.Element.Element == SourceBase.Item
{
    var sections = [[(value: Item, related: ItemRelatedCache)]]()
    
    override var multiType: SourceMultipleType { .multiple }
    
    override func item(at path: IndexPath) -> Item { sections[path].value }
    override func itemRelatedCache(at path: IndexPath) -> ItemRelatedCache { sections[path].related }
    
    override func numbersOfSections() -> Int { sections.count }
    override func numbersOfItems(in section: Int) -> Int { sections[section].count }
    
    override var isEmpty: Bool { sections.isEmpty }
    
    override func setup() {
        sections = source.map { $0.map { ($0, related: .init()) } }
        sourceType = .section
    }
}


final class RangeReplacableSectionsCoordinator<SourceBase: DataSource>: SectionsCoordinator<SourceBase>
where
    SourceBase.SourceBase == SourceBase,
    SourceBase.Source: RangeReplaceableCollection,
    SourceBase.Source.Element: RangeReplaceableCollection,
    SourceBase.Source.Element.Element == SourceBase.Item
{
    
    
}
