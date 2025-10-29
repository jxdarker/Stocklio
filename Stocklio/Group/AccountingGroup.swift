import Foundation
import SwiftUI
import Combine

class AccountingGroup: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var items: [AccountingElementBase]
    
    init(name: String, items: [AccountingElementBase] = []) {
        self.name = name
        self.items = items
    }
    
    func addItem(_ item: AccountingElementBase) {
        items.append(item)
        objectWillChange.send()  // 觸發 UI 更新
    }
    
    func removeItem(_ item: AccountingElementBase) {
        items.removeAll { $0.id == item.id }
        objectWillChange.send()  // 觸發 UI 更新
    }
}

// 預設群組
extension AccountingGroup {
    static func allItemsGroup(items: [AccountingElementBase]) -> AccountingGroup {
        return AccountingGroup(name: "所有項目", items: items)
    }
}
