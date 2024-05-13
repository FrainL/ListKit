//
//  ListAdapter+NSCollectionView.swift
//  ListKit
//
//  Created by Frain on 2023/8/1.
//

#if os(macOS)
import AppKit

// MARK: - Collection View Data Source
public extension ListAdapter {
    var itemForRepresentedObject: IndexFunction<NSCollectionView, List, IndexPath, NSCollectionViewItem, (ListIndexContext<NSCollectionView, IndexPath>) -> NSCollectionViewItem, IndexPath> {
        toFunction(#selector(NSCollectionViewDataSource.collectionView(_:itemForRepresentedObjectAt:)), toClosure())
    }
}

public extension ListAdapter where View: NSCollectionView {
    var supplementaryViewForItem: ElementFunction<(IndexPath, NSCollectionView.SupplementaryElementKind), NSView, (ElementContext, CollectionView.SupplementaryViewType) -> NSView> {
        toFunction(#selector(NSCollectionViewDataSource.collectionView(_:viewForSupplementaryElementOfKind:at:)), \.0) { closure in { context, input in closure(context, .init(rawValue: input.1)) } }
    }
}

// MARK: - Collection View Delegate
public extension ListAdapter where View: NSCollectionView {
    // MARK: - Managing the Selection
    var shouldSelectItem: ElementFunction<IndexPath, Bool, (ElementContext) -> Bool> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:shouldSelectItemsAt:)), toClosure())
    }
    
    var shouldDeselectItem: ElementFunction<IndexPath, Bool, (ElementContext) -> Bool> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:shouldDeselectItemsAt:)), toClosure())
    }
    
    var didSelectItem: ElementFunction<IndexPath, Void, (ElementContext) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:didSelectItemsAt:)), toClosure())
    }
    
    var didDeselectItem: ElementFunction<IndexPath, Void, (ElementContext) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:didDeselectItemsAt:)), toClosure())
    }
    
    // MARK: - Managing Item Highlighting
    var shouldChangeItem: ElementFunction<IndexPath, Bool, (ElementContext) -> Bool> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:shouldChangeItemsAt:to:)), toClosure())
    }
    
    var didChangeItem: ElementFunction<IndexPath, Void, (ElementContext) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:didChangeItemsAt:to:)), toClosure())
    }
    
    // MARK: - Tracking the Addition and Removal of Items
    var willDisplayForItem: ElementFunction<(IndexPath, NSCollectionViewItem), Void, (ElementContext, NSCollectionViewItem) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:willDisplay:forRepresentedObjectAt:)), \.0, toClosure())
    }
    
    var didEndDisplayingItem: Function<(IndexPath, NSCollectionViewItem), Void, (ListContext, IndexPath, NSCollectionViewItem) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplaying:forRepresentedObjectAt:)), toClosure())
    }
    
    var willDisplaySupplementaryView: ElementFunction<(IndexPath, NSView, String), Void, (ElementContext, NSView, CollectionView.SupplementaryViewType) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:willDisplay:forRepresentedObjectAt:)), \.0) { closure in { context, input in closure(context, input.1, .init(rawValue: input.2)) } }
    }
    
    var didEndDisplayingSupplementaryView: Function<(NSView, NSCollectionView.SupplementaryElementKind, IndexPath), Void, (ListContext, NSView, NSCollectionView.SupplementaryElementKind, IndexPath) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:))) { closure in { context, input in closure(context, input.0, .init(input.1), input.2) } }
    }
    
    // MARK: - Handling Layout Changes
    var transitionLayoutForOldLayoutNewLayout: Function<(NSCollectionViewLayout, NSCollectionViewLayout), NSCollectionViewTransitionLayout, (ListContext, NSCollectionViewLayout, NSCollectionViewLayout) -> NSCollectionViewTransitionLayout> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:transitionLayoutForOldLayout:newLayout:)), toClosure())
    }
                   
    // MARK: - Drag and Drop Support
    var canDragItems: Function<(Set<IndexPath>, NSEvent), Bool, (ListContext, Set<IndexPath>, NSEvent) -> Bool> {
        toFunction(canDragItemsAtIndexPathsSelector, toClosure())
    }
    
    var pasteboardWriterForItem: Function<IndexPath, NSPasteboardWriting?, (ListContext, IndexPath) -> NSPasteboardWriting?> {
        toFunction(pasteboardWriterForItemAtIndexPathSelector, toClosure())
    }
    
    var writeItems: Function<(Set<IndexPath>, NSPasteboard), Bool, (ListContext, Set<IndexPath>, NSPasteboard) -> Bool> {
        toFunction(writeItemsAtIndexPathsSelector, toClosure())
    }
    
    var namesOfPromisedFilesDroppedAtDestination: Function<(URL, Set<IndexPath>), [String], (ListContext, URL, Set<IndexPath>) -> [String]> {
        toFunction(namesOfPromisedFilesDroppedAtDestinationSelector, toClosure())
    }
    
    var draggingImageForItems: Function<(Set<IndexPath>, NSEvent, NSPointPointer), NSImage, (ListContext, Set<IndexPath>, NSEvent, NSPointPointer) -> NSImage> {
        toFunction(draggingImageForItemsAtIndexPathsSelector, toClosure())
    }
    
    var draggingSessionForItems: Function<(NSDraggingSession, NSPoint, Set<IndexPath>), Void, (ListContext, NSDraggingSession, NSPoint, Set<IndexPath>) -> Void> {
        toFunction(draggingSessionSelector, toClosure())
    }
    
    var draggingSessionEnded: Function<(NSDraggingSession, NSPoint, NSDragOperation), Void, (ListContext, NSDraggingSession, NSPoint, NSDragOperation) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:draggingSession:endedAt:dragOperation:)), toClosure())
    }
    
    var updateDraggingItemsForDrag: Function<NSDraggingInfo, Void, (ListContext, NSDraggingInfo) -> Void> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:updateDraggingItemsForDrag:)), toClosure())
    }
    
    var validateDrop: Function<(NSDraggingInfo, AutoreleasingUnsafeMutablePointer<NSIndexPath>, UnsafeMutablePointer<NSCollectionView.DropOperation>), NSDragOperation, (ListContext, NSDraggingInfo, AutoreleasingUnsafeMutablePointer<NSIndexPath>, UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:validateDrop:proposedIndexPath:dropOperation:)), toClosure())
    }
    
    var acceptDrop: Function<(NSDraggingInfo, IndexPath, NSCollectionView.DropOperation), Bool, (ListContext, NSDraggingInfo, IndexPath, NSCollectionView.DropOperation) -> Bool> {
        toFunction(#selector(NSCollectionViewDelegate.collectionView(_:acceptDrop:indexPath:dropOperation:)), toClosure())
    }
}

public extension ListAdapter where View: NSCollectionView {
    // MARK: - Getting the Size of Items
    var layoutSizeForItem: ElementFunction<(IndexPath, NSCollectionViewLayout), CGSize, (ElementContext, NSCollectionViewLayout) -> CGSize> {
        toFunction(#selector(NSCollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:)), \.0, toClosure())
    }
}

#endif
