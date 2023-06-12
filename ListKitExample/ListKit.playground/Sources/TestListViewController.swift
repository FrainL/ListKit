import ListKit
import UIKit

// swiftlint:disable comment_spacing orphaned_doc_comment

public class TestListViewController: UIViewController, UpdatableTableListAdapter {
    public var toggle = true

    lazy var itemSource = ItemSource()
    lazy var itemsSource = Models([1.0, 2.0, 3.0]) // .removeEmptySection
        .cellForRow()
        .didSelectRow { [unowned self] context in
//            batchRemove(at: context.item)
        }
        .headerTitleForSection("items")

    final class ItemSource: UpdatableTableListAdapter {
        var toggle = true

        public var list: TableList {
            buildList {
                if toggle {
                    Model(true)
                        .cellForRow()
                        .didSelectRow { [unowned self] context in
                            context.deselect(animated: false)
                            toggle.toggle()
                            performUpdate()
                        }
                } else {
                    Models([false, false, false])
                        .cellForRow()
                        .didSelectRow { [unowned self] context in
                            context.deselect(animated: false)
                            toggle.toggle()
                            performUpdate()
                        }
                }
            }
            .headerTitleForSection("item")
        }
    }

    public var list: TableList {
        if toggle {
            itemSource
            itemsSource
        }
        Sections([[1, 2, 3], [1, 2, 3]])
            .cellForRow()
            .headerTitleForSection("sections")
        buildList {
            Model(2)
                .cellForRow()
                .didSelectRow { context, model in
                    context.deselect(animated: false)
                    print(model)
                }
            Models(["a", "b", "c"])
                .cellForRow()
                .didSelectRow { context, model in
                    context.deselect(animated: false)
                    print(model)
                }
        }.headerTitleForSection("sources")
    }

    public override func viewDidLoad() {
        apply(by: tableView)
        configActions()
    }

    func configActions() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refresh)
        )
    }

    @objc func refresh() {
        toggle.toggle()
        performUpdate()
    }

    func batchRemove(at item: Int) {
//        itemsSource.perform(.remove(at: item))
    }
}

extension TestListViewController {
    var tableView: UITableView {
        let tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return tableView
    }
}

#if canImport(SwiftUI) && EXAMPLE

import SwiftUI

@available(iOS 13.0, *)
struct TestList_Preview: UIViewControllerRepresentable, PreviewProvider {
    static var previews: some View { TestList_Preview() }

    func makeUIViewController(context: Self.Context) -> UINavigationController {
        UINavigationController(rootViewController: TestListViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Self.Context) {

    }
}

#endif

//extension TestListViewController {
//    var source: AnyTableSources {
//        AnyTableSources {
//            if toggle {
//                Sources(model: "b")
//                    .tableViewCellForRow()
//                    .tableViewDidSelectRow { (context, model) in
//                        context.deselectItem(animated: false)
//                        print(item)
//                    }
//            }
//            Sources(id: 1, items: ["a", "b", "c"])
//                .tableViewCellForRow()
//                .tableViewDidSelectRow { (context, model) in
//                    context.deselectItem(animated: false)
//                    print(item)
//                }
//                .tableViewHeaderTitleForSection { (context) -> String? in
//                    "sources"
//                }
//        }
//    }
//}
//
//public extension TestListViewController {
//    static var source = [AnyTableSources]()
//
//    typealias Item = Any
//    var source: [AnyTableSources] {
//        []
//    }
//
//    func configActions() {
//        navigationItem.rightBarButtonItems = [
//            UIBarButtonItem(
//                barButtonSystemItem: .add,
//                target: self,
//                action: #selector(add)
//            ),
//            UIBarButtonItem(
//                barButtonSystemItem: .refresh,
//                target: self,
//                action: #selector(refresh)
//            )
//        ]
//    }
//
//    @objc func add() {
//        let source = AnyTableSources {
//            itemsSource
//        }
//        perform(.append(source))
//    }
//
//    @objc func refresh() {
//        var update = ListUpdate<SourceBase>()
//        update.add(.subsource(itemsSource, update: [.append(4.0), .update(0.0, at: 0)]))
//        perform(update)
//
//        itemSource.toggle.toggle()
//        itemSource.performUpdate()
//    }
//}
