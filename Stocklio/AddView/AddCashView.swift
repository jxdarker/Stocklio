import SwiftUI

struct AddCashView: View {
    @Environment(\.dismiss) var dismiss
    var onAddItem: (AccountingElementBase) -> Void = { _ in }
    
    @State private var accountName = ""
    @State private var balance = ""
    @State private var selectedCurrency: Currency = .USD
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
                    
                    Picker("货币", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.rawValue)
                                Text(currency.symbol)
                                    .foregroundColor(.secondary)
                            }
                            .tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("预览")) {
                    HStack {
                        Text("金额显示")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(selectedCurrency.symbol)\(getPreviewBalance())")
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("添加现金账户")
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
    
    private func getPreviewBalance() -> String {
        guard let number = numberFormatter.number(from: balance) else {
            return "0.00"
        }
        return String(format: "%.2f", number.doubleValue)
    }
    
    private func saveItem() {
        if let number = numberFormatter.number(from: balance) {
            let newItem = CashElement(
                accountName: accountName,
                balance: number.doubleValue
            )
            newItem.currency = selectedCurrency // 設定貨幣
            onAddItem(newItem)
        }
    }
}

#Preview {
    AddCashView()
}
