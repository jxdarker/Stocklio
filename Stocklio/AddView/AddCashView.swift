import SwiftUI

struct AddCashView: View {
    @Environment(\.dismiss) var dismiss
    var onAddItem: (AccountingElementBase) -> Void = { _ in }
    
    @State private var accountName = ""
    @State private var balance = ""
    @State private var showAlert = false
    
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
                Section(header: Text("账户信息")) {
                    TextField("账户名称", text: $accountName)
                    
                    TextField("余额", text: $balance)
                        .keyboardType(.decimalPad)
                        .onChange(of: balance) { oldValue, newValue in
                            validateNumericInput(newValue)
                        }
                }
            }
            .navigationTitle("添加账户")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    if isValidBalance() {
                        saveItem()
                        dismiss()
                    } else {
                        showAlert = true
                    }
                }
                .disabled(accountName.isEmpty || balance.isEmpty)
            )
            .alert("輸入錯誤", isPresented: $showAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("請輸入有效的數字金額")
            }
        }
    }
    
    private func validateNumericInput(_ input: String) {
        // 如果輸入為空，允許
        if input.isEmpty {
            balance = ""
            return
        }
        
        // 使用 NumberFormatter 驗證
        if numberFormatter.number(from: input) != nil {
            balance = input
        } else {
            // 如果無效，恢復到上次的有效值
            // 這裡簡單處理，可以根據需要調整
            let filtered = input.filter { "0123456789.".contains($0) }
            let components = filtered.components(separatedBy: ".")
            if components.count <= 2 {
                balance = filtered
            }
        }
    }
    
    private func isValidBalance() -> Bool {
        return numberFormatter.number(from: balance) != nil
    }
    
    private func saveItem() {
        if let number = numberFormatter.number(from: balance) {
            let newItem = CashElement(
                accountName: accountName,
                balance: number.doubleValue
            )
            onAddItem(newItem)
        }
    }
}


#Preview {
    AddCashView()
}
