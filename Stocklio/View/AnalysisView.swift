import SwiftUI
import Charts

struct AnalysisView: View {
    let items: [AccountingElementBase]
    @State private var selectedTimeRange: TimeRange = .oneMonth
    
    enum TimeRange: String, CaseIterable {
        case oneMonth = "1個月"
        case sixMonths = "6個月"
        case oneYear = "1年"
        
        var dateRange: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .oneMonth:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .sixMonths:
                return calendar.date(byAdding: .month, value: -6, to: now) ?? now
            case .oneYear:
                return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 圓餅圖
                    pieChartSection
                    
                    // 折線圖 + 時間選擇器
                    lineChartWithTimeRangeSection
                }
                .padding()
            }
            .navigationTitle("投資分析")
        }
    }
    
    // 計算所有股票項目 - 修正：不需要 filter balance
    private var stockItems: [AccountingElementBase] {
        items.compactMap { $0 as? StockElement }
    }
    
    // 計算總資產價值 - 使用 GetBalance
    private var totalValue: Double {
        items.reduce(0.0) { result, item in
            result + item.GetBalance(currency: .TWD) // 使用基準貨幣計算總值
        }
    }
    
    // 生成模擬的歷史數據
    private var historicalData: [HistoricalValue] {
        let endDate = Date()
        let startDate = selectedTimeRange.dateRange
        let calendar = Calendar.current
        
        var data: [HistoricalValue] = []
        var currentDate = startDate
        
        // 生成模擬數據點
        while currentDate <= endDate {
            // 模擬資產波動
            let baseValue = totalValue
            let randomFactor = Double.random(in: 0.8...1.2)
            let simulatedValue = baseValue * randomFactor
            
            data.append(HistoricalValue(date: currentDate, value: simulatedValue))
            
            // 根據時間範圍調整間隔
            switch selectedTimeRange {
            case .oneMonth:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .sixMonths:
                currentDate = calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate
            case .oneYear:
                currentDate = calendar.date(byAdding: .day, value: 10, to: currentDate) ?? currentDate
            }
        }
        
        return data
    }
    
    // 圓餅圖區塊
    private var pieChartSection: some View {
        VStack {
            Text("資產分布")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if items.isEmpty {
                ContentUnavailableView(
                    "暫無數據",
                    systemImage: "chart.pie",
                    description: Text("請先添加投資項目")
                )
                .frame(height: 200)
            } else {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("金額", item.GetBalance(currency: .TWD)),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("資產", item.accountName))
                    .annotation(position: .overlay) {
                        let itemBalance = item.GetBalance(currency: .TWD)
                        let percentage = totalValue > 0 ? (itemBalance / totalValue) * 100 : 0
                        if percentage > 5 {
                            Text("\(percentage, specifier: "%.0f")%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
            }
            
            Text("總資產: $\(totalValue, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    // 折線圖 + 時間範圍選擇器
    private var lineChartWithTimeRangeSection: some View {
        VStack(spacing: 16) {
            // 標題和時間選擇器在同一行
            HStack {
                Text("資產趨勢")
                    .font(.headline)
                
                Spacer()
                
                // 時間範圍選擇器
                HStack(spacing: 8) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTimeRange = range
                            }
                        }) {
                            Text(range.rawValue)
                                .font(.caption)
                                .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                                .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                                )
                        }
                    }
                }
            }
            
            // 折線圖
            if historicalData.isEmpty {
                ContentUnavailableView(
                    "暫無歷史數據",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("無法生成趨勢圖表")
                )
                .frame(height: 200)
            } else {
                Chart(historicalData) { data in
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
                                Text(formatDateForAxis(date, timeRange: selectedTimeRange))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(amount/1000, specifier: "%.0f")K")
                                    .font(.caption2)
                            }
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
    
    // 格式化日期顯示
    private func formatDateForAxis(_ date: Date, timeRange: TimeRange) -> String {
        let formatter = DateFormatter()
        switch timeRange {
        case .oneMonth:
            formatter.dateFormat = "MM/dd"
        case .sixMonths:
            formatter.dateFormat = "MMM"
        case .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
}

// 歷史數據模型
struct HistoricalValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    AnalysisView(items: [])
}
