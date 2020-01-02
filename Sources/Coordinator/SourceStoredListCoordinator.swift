//
//  SourceStoredListCoordinator.swift
//  ListKit
//
//  Created by Frain on 2019/12/17.
//

class SourceStoredListCoordinator<SourceBase: DataSource>: ListCoordinator<SourceBase> {
    var _source: SourceBase.Source
    override var source: SourceBase.Source { _source }
    
    override init(sourceBase: SourceBase, storage: CoordinatorStorage<SourceBase>? = nil) {
        _source = storage?.source ?? sourceBase.source
        
        super.init(sourceBase: sourceBase)
    }
}