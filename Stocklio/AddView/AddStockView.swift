import SwiftUI
import Foundation

struct AddStockView: View {
    @Environment(\.dismiss) var dismiss
    var onAddItem: (AccountingElementBase) -> Void = { _ in }
    
    @State private var accountName = ""
    @State private var shares = ""
    @State private var costPrice = ""
    @State private var symbol = ""
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("股票信息")) {
                    TextField("股票名稱", text: $accountName)
                    TextField("股票代碼 (如: AAPL)", text: $symbol)
                    TextField("持股數量", text: $shares)
                        .keyboardType(.decimalPad)
                        .onChange(of: shares) { oldValue, newValue in
                            // 限制只能輸入數字和小數點
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            let components = filtered.components(separatedBy: ".")
                            if components.count <= 2 {
                                shares = filtered
                            } else {
                                shares = oldValue
                            }
                        }
                    TextField("成本價", text: $costPrice) // 新增
                        .keyboardType(.decimalPad)

                }
            }
            .navigationTitle("添加股票")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveItem()
                    dismiss()
                }
                .disabled(accountName.isEmpty || shares.isEmpty || symbol.isEmpty || Double(shares) == nil)
            )
        }
    }
    
    private func saveItem() {
        if let sharesNumber = numberFormatter.number(from: shares),
           let costPriceNumber = numberFormatter.number(from: costPrice) {
            let newItem = StockElement(
                accountName: accountName,
                shares: sharesNumber.doubleValue,
                symbol: symbol,
                costPrice: costPriceNumber.doubleValue // 新增
            )
            onAddItem(newItem)
        }
    }
}

#Preview {
    AddStockView()
}
