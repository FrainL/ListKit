//
//  ListDelegates+NSCollectionView.swift
//  ListKit
//
//  Created by Frain on 2023/8/1.
//

#if os(macOS)
import AppKit

extension Delegate: NSCollectionViewDataSource {
    // MARK: - Getting the Number of Sections and Items
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        numbersOfSections()
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfItemsInSection(section)
    }

    // MARK: - Configuring Items and Supplementary Views
    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        apply(#selector(NSCollectionViewDataSource.collectionView(_:itemForRepresentedObjectAt:)), view: collectionView, with: indexPath, index: indexPath, default: NSCollectionViewItem())
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
        at indexPath: IndexPath
    ) -> NSView {
        apply(#selector(NSCollectionViewDataSource.collectionView(_:viewForSupplementaryElementOfKind:at:)), view: collectionView, with: (indexPath, kind), index: indexPath, default: NSView())
    }
}

extension Delegate: NSCollectionViewDelegate {
    // MARK: - Managing the Selection
    func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        return apply(#selector(NSCollectionViewDelegate.collectionView(_:shouldSelectItemsAt:)), view: collectionView, with: indexPaths.first!, index: indexPaths.first!, default: true) ? indexPaths : []
    }

    func collectionView(_ collectionView: NSCollectionView, shouldDeselectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        return apply(#selector(NSCollectionViewDelegate.collectionView(_:shouldDeselectItemsAt:)), view: collectionView, with: indexPaths.first!, index: indexPaths.first!, default: true) ? indexPaths : []
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:didSelectItemsAt:)), view: collectionView, with: indexPaths.first!, index: indexPaths.first!, default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:didDeselectItemsAt:)), view: collectionView, with: indexPaths.first!, index: indexPaths.first!, default: ())
    }

    // MARK: - Managing Item Highlighting
    func collectionView(_ collectionView: NSCollectionView, shouldChangeItemsAt indexPaths: Set<IndexPath>, to highlightState: NSCollectionViewItem.HighlightState) -> Set<IndexPath> {
        return apply(#selector(NSCollectionViewDelegate.collectionView(_:shouldChangeItemsAt:to:)), view: collectionView, with: (indexPaths, highlightState), index: indexPaths.first!, default: true) ? indexPaths : []
    }

    func collectionView(_ collectionView: NSCollectionView, didChangeItemsAt indexPaths: Set<IndexPath>, to highlightState: NSCollectionViewItem.HighlightState) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:didChangeItemsAt:to:)), view: collectionView, with: (indexPaths, highlightState), index: indexPaths.first!, default: ())
    }

    // MARK: - Tracking the Addition and Removal of Items
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:willDisplay:forRepresentedObjectAt:)), view: collectionView, with: (item, indexPath), default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, didEndDisplaying item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplaying:forRepresentedObjectAt:)), view: collectionView, with: (item, indexPath), default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, willDisplaySupplementaryView view: NSView, forElementKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)), view: collectionView, with: (view, elementKind, indexPath), default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, didEndDisplayingSupplementaryView view: NSView, forElementOfKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:)), view: collectionView, with: (view, elementKind, indexPath), default: ())
    }


    // MARK: - Handling Layout Changes
    func collectionView(_ collectionView: NSCollectionView, transitionLayoutForOldLayout fromLayout: NSCollectionViewLayout, newLayout toLayout: NSCollectionViewLayout) -> NSCollectionViewTransitionLayout {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:transitionLayoutForOldLayout:newLayout:)), view: collectionView, with: (fromLayout, toLayout), default: NSCollectionViewTransitionLayout())
    }

    // MARK: - Drag and Drop Support
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        apply(canDragItemsAtIndexPathsSelector, view: collectionView, with: (indexPaths, event), default: true)
    }

    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        apply(pasteboardWriterForItemAtIndexPathSelector, view: collectionView, with: indexPath, default: nil)
    }

    func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
        apply(writeItemsAtIndexPathsSelector, view: collectionView, with: (indexPaths, pasteboard), default: false)
    }

    func collectionView(_ collectionView: NSCollectionView, namesOfPromisedFilesDroppedAtDestination dropURL: URL, forDraggedItemsAt indexPaths: Set<IndexPath>) -> [String] {
        apply(namesOfPromisedFilesDroppedAtDestinationSelector, view: collectionView, with: (dropURL, indexPaths), default: [])
    }

    func collectionView(_ collectionView: NSCollectionView, draggingImageForItemsAt indexPaths: Set<IndexPath>, with event: NSEvent, offset dragImageOffset: NSPointPointer) -> NSImage {
        apply(draggingImageForItemsAtIndexPathsSelector, view: collectionView, with: (indexPaths, event, dragImageOffset), default: NSImage())
    }

    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        apply(draggingSessionSelector, view: collectionView, with: (session, screenPoint, indexPaths), default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:draggingSession:endedAt:dragOperation:)), view: collectionView, with: (session, screenPoint, operation), default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:updateDraggingItemsForDrag:)), view: collectionView, with: draggingInfo, default: ())
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:validateDrop:proposedIndexPath:dropOperation:)), view: collectionView, with: (draggingInfo, proposedDropIndexPath, proposedDropOperation), default: [])
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        apply(#selector(NSCollectionViewDelegate.collectionView(_:acceptDrop:indexPath:dropOperation:)), view: collectionView, with: (draggingInfo, indexPath, dropOperation), default: false)
    }
}

extension Delegate: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        apply(#selector(NSCollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:)), view: collectionView, with: (indexPath, collectionViewLayout), index: indexPath, default: (collectionViewLayout as? NSCollectionViewFlowLayout)?.itemSize ?? .zero)
    }
}

#endif
