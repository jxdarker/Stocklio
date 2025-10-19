import SwiftUI

struct MainView: View {
    @Binding var items: [AccountingElementBase]
    @State private var showAddCashView = false
    @State private var showAddStockView = false
    @State private var selectedCurrency: Currency = .TWD
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        item.GetDetailView()
                            .navigationTitle("账户详情")
                    } label: {
                        CurrencyAdjustedListView(
                            item: item,
                            displayCurrency: selectedCurrency, // 傳入選擇的顯示貨幣
                            refreshTrigger: refreshTrigger
                        )
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteItems)
            }
            .id(refreshTrigger) // 當 refreshTrigger 改變時強制刷新
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Button {
                                selectedCurrency = currency // 只改變顯示貨幣，不改變項目貨幣
                                refreshDisplay() // 刷新顯示
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
    
    private func refreshDisplay() {
        // 觸發 UI 刷新
        refreshTrigger = UUID()
        
        // 預先加載匯率到緩存（可選，提升體驗）
        Task {
            for item in items {
                if item.currency != selectedCurrency {
                    // 預先觸發匯率查詢，填充緩存
                    let _ = await Currency.convert(
                        amount: 1.0,
                        from: item.currency,
                        to: selectedCurrency,
                        useCache: true
                    )
                }
            }
        }
    }
}

struct CurrencyAdjustedListView: View {
    let item: AccountingElementBase
    let displayCurrency: Currency
    let refreshTrigger: UUID
    
    @State private var convertedBalance: Double = 0.0
    @State private var originalBalance: Double = 0.0
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.accountName)
                    .font(.headline)
                
                Text(item.currency.rawValue) // 顯示項目的原始貨幣
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    // 顯示轉換後的金額（使用 displayCurrency）
                    Text("\(displayCurrency.symbol)\(convertedBalance, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    // 如果顯示貨幣與項目貨幣不同，顯示原始金額
                    if item.currency != displayCurrency {
                        Text("\(item.currency.symbol)\(originalBalance, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .task(id: refreshTrigger) {
            await loadBalances()
        }
        .onChange(of: displayCurrency) { _ in
            Task {
                await loadBalances()
            }
        }
    }
    
    private func loadBalances() async {
        isLoading = true
        
        // 並行加載轉換後金額和原始金額
        async let convertedBalanceTask = item.getBalanceAsync(currency: displayCurrency)
        async let originalBalanceTask = item.getBalanceAsync(currency: item.currency)
        
        let (converted, original) = await (convertedBalanceTask, originalBalanceTask)
        
        await MainActor.run {
            convertedBalance = converted
            originalBalance = original
            isLoading = false
        }
    }
}
