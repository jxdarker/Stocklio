import SwiftUI

struct MainView: View {
    @Binding var items: [AccountingElementBase]
    @State private var showAddCashView = false
    @State private var showAddStockView = false
    @State private var selectedCurrency: Currency = .TWD
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        item.GetDetailView()
                            .navigationTitle("账户详情")
                    } label: {
                        CurrencyAdjustedListView(item: item, displayCurrency: selectedCurrency)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                // 移除 EditButton，添加幣種選擇器在左邊
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Button {
                                selectedCurrency = currency
                            } label: {
                                HStack {
                                    Text(currency.rawValue)
                                    if selectedCurrency == currency {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                            Text(selectedCurrency.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // 右邊保持添加按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAddCashView = true
                        } label: {
                            Label("現金賬戶", systemImage: "dollarsign.circle")
                        }
                        
                        Button {
                            showAddStockView = true
                        } label: {
                            Label("股票投資", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    } label: {
                        Label("添加账户", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCashView) {
                AddCashView(onAddItem: { newItem in
                    items.append(newItem)
                })
            }
            .sheet(isPresented: $showAddStockView) {
                AddStockView(onAddItem: { newItem in
                    items.append(newItem)
                })
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("暂无账户", systemImage: "dollarsign.circle")
                    } description: {
                        Text("点击右上角 + 添加第一个账户")
                    }
                }
            }
        } detail: {
            Text("选择一个账户")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            items.remove(atOffsets: offsets)
        }
    }
}

// 支援幣種轉換的列表視圖
struct CurrencyAdjustedListView: View {
    let item: AccountingElementBase
    let displayCurrency: Currency
    
    private var convertedBalance: Double {
        // 直接使用 item.GetBalance 方法，它會處理幣種轉換
        return item.GetBalance(currency: displayCurrency)
    }
    
    private var originalBalance: Double {
        // 取得原始幣種的金額
        return item.GetBalance(currency: item.currency)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.accountName)
                    .font(.headline)
                
                Text("原始幣種: \(item.currency.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(displayCurrency.symbol)\(convertedBalance, specifier: "%.2f")")
                    .font(.body)
                    .fontWeight(.semibold)
                
                // 如果不是原始幣種，顯示原始金額
                if item.currency != displayCurrency {
                    Text("\(item.currency.symbol)\(originalBalance, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
