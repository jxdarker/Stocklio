import SwiftUI
import Charts

struct AnalysisView: View {
    let group: Group
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var totalValue: Double = 0.0
    @State private var totalCostValue: Double = 0.0
    @State private var itemBalances: [UUID: Double] = [:]
    @State private var itemCostBalances: [UUID: Double] = [:]
    @State private var isLoading = false
    @State private var selectedCurrency: Currency = .TWD
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 總覽卡片（更新顯示成本和當前價值）
                overviewCard
                
                // 當前價值資產分布圓餅圖
                if !group.items.isEmpty {
                    currentValuePieChartSection
                }
                
                // 成本價值資產分布圓餅圖（新增）
                if !group.items.isEmpty {
                    costValuePieChartSection
                }
                
                // 資產趨勢折線圖
                if !group.items.isEmpty {
                    lineChartSection
                }
                
                // 項目列表
                itemsListSection
            }
            .padding()
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button {
                            selectedCurrency = currency
                            Task {
                                await loadAllBalances()
                            }
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
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadAllBalances()
        }
        .refreshable {
            await loadAllBalances()
        }
    }
    
    // 總覽卡片（更新顯示成本和收益）
    private var overviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("當前總價值")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(selectedCurrency.symbol)\(totalValue, specifier: "%.2f")")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("總成本")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(selectedCurrency.symbol)\(totalCostValue, specifier: "%.2f")")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("收益")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        let profit = totalValue - totalCostValue
                        let profitPercentage = totalCostValue > 0 ? (profit / totalCostValue) * 100 : 0
                        
                        Text("\(selectedCurrency.symbol)\(profit, specifier: "%.2f")")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(profit >= 0 ? .green : .red)
                        
                        Text("(\(profitPercentage, specifier: "%.1f")%)")
                            .font(.caption)
                            .foregroundColor(profit >= 0 ? .green : .red)
                    }
                }
            }
            
            // 資產類型統計
            if !group.items.isEmpty {
                HStack(spacing: 16) {
                    let stockCount = group.items.compactMap { $0 as? StockElement }.count
                    let cashCount = group.items.compactMap { $0 as? CashElement }.count
                    
                    StatBadge(count: stockCount, label: "股票", color: .green, icon: "chart.line.uptrend.xyaxis")
                    StatBadge(count: cashCount, label: "現金", color: .blue, icon: "dollarsign.circle")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    // 當前價值圓餅圖區塊
    private var currentValuePieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("當前價值分布")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isLoading {
                ProgressView("載入中...")
                    .frame(height: 250)
            } else {
                Chart(group.items) { item in
                    SectorMark(
                        angle: .value("金額", getItemBalance(item)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("資產", item.accountName))
                    .annotation(position: .overlay) {
                        let itemBalance = getItemBalance(item)
                        let percentage = totalValue > 0 ? (itemBalance / totalValue) * 100 : 0
                        if percentage > 8 {
                            Text("\(percentage, specifier: "%.0f")%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
                .chartLegend(.hidden)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    // 成本價值圓餅圖區塊（新增）
    private var costValuePieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("成本價值分布")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isLoading {
                ProgressView("載入中...")
                    .frame(height: 250)
            } else {
                Chart(group.items) { item in
                    SectorMark(
                        angle: .value("金額", getItemCostBalance(item)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("資產", item.accountName))
                    .annotation(position: .overlay) {
                        let itemCostBalance = getItemCostBalance(item)
                        let percentage = totalCostValue > 0 ? (itemCostBalance / totalCostValue) * 100 : 0
                        if percentage > 8 {
                            Text("\(percentage, specifier: "%.0f")%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
                .chartLegend(.hidden)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    // 折線圖區塊
    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("資產趨勢")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 時間範圍選擇器
                Picker("時間範圍", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            Chart(generateHistoricalData()) { data in
                LineMark(
                    x: .value("日期", data.date),
                    y: .value("資產", data.value)
                )
                .foregroundStyle(.blue.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("日期", data.date),
                    y: .value("資產", data.value)
                )
                .foregroundStyle(.blue.opacity(0.1).gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDateForAxis(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatAmountForAxis(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    // 項目列表區塊
    private var itemsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("項目明細")
                .font(.title2)
                .fontWeight(.semibold)
            
            if group.items.isEmpty {
                ContentUnavailableView(
                    "暫無項目",
                    systemImage: "list.bullet",
                    description: Text("此群組目前沒有項目")
                )
                .frame(height: 150)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(group.items) { item in
                        NavigationLink {
                            item.GetDetailView()
                                .navigationTitle("項目詳情")
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
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("\(selectedCurrency.symbol)\(getItemBalance(item), specifier: "%.2f")")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    if item.currency != selectedCurrency {
                                        let originalBalance = getItemBalance(item)
                                        Text("原始: \(item.currency.symbol)\(originalBalance, specifier: "%.2f")")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    private func loadAllBalances() async {
        isLoading = true
        
        // 同時載入當前價值和成本價值
        let (balances, costBalances) = await withTaskGroup(of: (UUID, Double, Double).self) { taskGroup in
            for item in group.items {
                taskGroup.addTask {
                    let currentBalance = await item.getBalanceAsync(currency: selectedCurrency)
                    var costBalance = currentBalance // 預設為當前價值（現金項目）
                    
                    // 如果是股票項目，使用成本價值
                    if let stockItem = item as? StockElement {
                        costBalance = await stockItem.getCostBalanceAsync(currency: selectedCurrency)
                    }
                    
                    return (item.id, currentBalance, costBalance)
                }
            }
            
            var currentResults: [UUID: Double] = [:]
            var costResults: [UUID: Double] = [:]
            
            for await (id, currentBalance, costBalance) in taskGroup {
                currentResults[id] = currentBalance
                costResults[id] = costBalance
            }
            
            return (currentResults, costResults)
        }
        
        let total = balances.values.reduce(0.0, +)
        let totalCost = costBalances.values.reduce(0.0, +)
        
        await MainActor.run {
            itemBalances = balances
            itemCostBalances = costBalances
            totalValue = total
            totalCostValue = totalCost
            isLoading = false
        }
    }
    
    // 獲取單個項目的當前餘額
    private func getItemBalance(_ item: AccountingElementBase) -> Double {
        return itemBalances[item.id] ?? 0.0
    }
    
    // 獲取單個項目的成本餘額
    private func getItemCostBalance(_ item: AccountingElementBase) -> Double {
        return itemCostBalances[item.id] ?? 0.0
    }
    
    // 生成模擬歷史數據
    private func generateHistoricalData() -> [HistoricalValue] {
        let endDate = Date()
        let startDate = selectedTimeRange.dateRange
        let calendar = Calendar.current
        
        var data: [HistoricalValue] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let baseValue = totalValue
            let randomFactor = Double.random(in: 0.9...1.1)
            let simulatedValue = baseValue * randomFactor
            
            data.append(HistoricalValue(date: currentDate, value: simulatedValue))
            
            switch selectedTimeRange {
            case .oneMonth:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .threeMonths:
                currentDate = calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate
            case .sixMonths:
                currentDate = calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate
            case .oneYear:
                currentDate = calendar.date(byAdding: .day, value: 10, to: currentDate) ?? currentDate
            }
        }
        
        return data
    }
    
    // 格式化日期
    private func formatDateForAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeRange {
        case .oneMonth:
            formatter.dateFormat = "MM/dd"
        case .threeMonths, .sixMonths, .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    // 格式化金額
    private func formatAmountForAxis(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", amount/1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", amount/1_000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}

// 統計徽章組件 - 修正錯誤
struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// 歷史數據模型
struct HistoricalValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    NavigationView {
        AnalysisView(group: Group(name: "測試群組", items: []))
    }
}
