import SwiftUI

struct AddItemToGroupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var group: Group  // 正確使用 @ObservedObject
    let allItems: [AccountingElementBase]
    
    // 過濾出尚未在群組中的項目
    var availableItems: [AccountingElementBase] {
        allItems.filter { item in
            !group.items.contains { $0.id == item.id }  // 直接使用 group.items
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableItems) { item in
                    Button {
                        group.addItem(item)  // 直接呼叫 group 的方法
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.accountName)
                                    .font(.headline)
                                Text(item.currency.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("添加項目到 \(group.name)")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                }
            )
        }
    }
}
