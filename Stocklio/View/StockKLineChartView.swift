import SwiftUI
import Charts

struct StockKLineChartView: View {
    let kLineData: [KLineData]
    let symbol: String
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var candleInterval: CandleInterval = .auto
    
    enum TimeRange: String, CaseIterable {
        case oneDay = "1天"
        case oneWeek = "1週"
        case oneMonth = "1月"
        case threeMonths = "3月"
        case sixMonths = "6月"
        case oneYear = "1年"
        
        var days: Int {
            switch self {
            case .oneDay: return 1
            case .oneWeek: return 7
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            }
        }
    }
    
    enum CandleInterval: String, CaseIterable {
        case auto = "自動"
        case oneMinute = "1分"
        case fiveMinutes = "5分"
        case fifteenMinutes = "15分"
        case oneHour = "1時"
        case fourHours = "4時"
        case oneDay = "1日"
        case oneWeek = "1週"
        
        var timeInterval: TimeInterval {
            switch self {
            case .auto: return 0
            case .oneMinute: return 60
            case .fiveMinutes: return 300
            case .fifteenMinutes: return 900
            case .oneHour: return 3600
            case .fourHours: return 14400
            case .oneDay: return 86400
            case .oneWeek: return 604800
            }
        }
    }
    
    // 自動計算合適的間隔
    private var autoInterval: TimeInterval {
        switch selectedTimeRange {
        case .oneDay:
            return 900 // 15分鐘
        case .oneWeek:
            return 3600 // 1小時
        case .oneMonth:
            return 86400 // 1天
        case .threeMonths:
            return 86400 // 1天
        case .sixMonths:
            return 86400 // 1天
        case .oneYear:
            return 2592000 // 1個月
        }
    }
    
    // 當前間隔描述
    private var currentIntervalDescription: String {
        if candleInterval == .auto {
            switch autoInterval {
            case 60: return "1分鐘"
            case 300: return "5分鐘"
            case 900: return "15分鐘"
            case 3600: return "1小時"
            case 86400: return "1日"
            case 2592000: return "1月"
            default: return "自動"
            }
        } else {
            return candleInterval.rawValue
        }
    }
    
    // 處理後的數據 - 根據間隔聚合
    private var processedData: [KLineData] {
        guard !kLineData.isEmpty else { return [] }
        
        let interval: TimeInterval
        if candleInterval == .auto {
            interval = autoInterval
        } else {
            interval = candleInterval.timeInterval
        }
        
        // 如果間隔是0或1天，直接返回原始數據（日K線）
        if interval == 0 || interval == 86400 {
            return filterByTimeRange(kLineData)
        }
        
        // 否則進行數據聚合
        return aggregateData(filterByTimeRange(kLineData), interval: interval)
    }
    
    // 根據時間範圍過濾數據
    private func filterByTimeRange(_ data: [KLineData]) -> [KLineData] {
        let calendar = Calendar.current
        let endDate = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) else {
            return data
        }
        
        return data.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    // 數據聚合函數
    private func aggregateData(_ data: [KLineData], interval: TimeInterval) -> [KLineData] {
        guard interval > 0 else { return data }
        
        var aggregated: [KLineData] = []
        var currentGroup: [KLineData] = []
        var groupStartTime: Date?
        
        for item in data.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let startTime = groupStartTime {
                if item.timestamp.timeIntervalSince(startTime) >= interval {
                    if let aggregatedCandle = createAggregatedCandle(from: currentGroup) {
                        aggregated.append(aggregatedCandle)
                    }
                    currentGroup = [item]
                    groupStartTime = item.timestamp
                } else {
                    currentGroup.append(item)
                }
            } else {
                groupStartTime = item.timestamp
                currentGroup = [item]
            }
        }
        
        if let aggregatedCandle = createAggregatedCandle(from: currentGroup) {
            aggregated.append(aggregatedCandle)
        }
        
        return aggregated
    }
    
    // 創建聚合的K線
    private func createAggregatedCandle(from group: [KLineData]) -> KLineData? {
        guard !group.isEmpty else { return nil }
        
        let sortedByTime = group.sorted(by: { $0.timestamp < $1.timestamp })
        let open = sortedByTime.first?.open ?? 0
        let close = sortedByTime.last?.close ?? 0
        let high = group.map { $0.high }.max() ?? 0
        let low = group.map { $0.low }.min() ?? 0
        let timestamp = sortedByTime.first?.timestamp ?? Date()
        let totalVolume = group.compactMap { $0.volume }.reduce(0, +)
        
        return KLineData(
            timestamp: timestamp,
            open: open,
            close: close,
            high: high,
            low: low,
            volume: totalVolume > 0 ? totalVolume : nil
        )
    }
    
    // 計算價格範圍
    private var priceRange: (min: Double, max: Double) {
        guard !processedData.isEmpty else { return (0, 100) }
        
        let allPrices = processedData.flatMap { [$0.low, $0.high] }
        let minPrice = allPrices.min() ?? 0
        let maxPrice = allPrices.max() ?? 100
        
        let range = maxPrice - minPrice
        let margin = range * 0.05
        
        return (minPrice - margin, maxPrice + margin)
    }
    
    // 動態 K 線寬度
    private func calculateCandleWidth() -> CGFloat {
        let dataCount = processedData.count
        
        switch dataCount {
        case 0...5: return 20
        case 6...10: return 15
        case 11...20: return 12
        case 21...30: return 10
        case 31...50: return 8
        case 51...80: return 6
        case 81...120: return 4
        case 121...200: return 3
        default: return 2
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 第一行：標題和時間範圍
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("K線圖")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(symbol) • \(currentIntervalDescription)K • \(processedData.count)根")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                selectedTimeRange = range
                            } label: {
                                Text(range.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(2)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            // 第二行：K線間隔選擇
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CandleInterval.allCases, id: \.self) { interval in
                        Button {
                            candleInterval = interval
                        } label: {
                            Text(interval.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(candleInterval == interval ? Color.orange : Color.gray.opacity(0.2))
                                .foregroundColor(candleInterval == interval ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(2)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // K線圖
            Chart(processedData) { data in
                LineMark(
                    x: .value("日期", data.timestamp),
                    y: .value("價格", data.high)
                )
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(data.isRising ? .red : .green)
                
                LineMark(
                    x: .value("日期", data.timestamp),
                    y: .value("價格", data.low)
                )
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(data.isRising ? .red : .green)
                
                BarMark(
                    x: .value("日期", data.timestamp),
                    yStart: .value("開盤", data.open),
                    yEnd: .value("收盤", data.close),
                    width: .fixed(calculateCandleWidth())
                )
                .foregroundStyle(data.isRising ? .red : .green)
            }
            .chartYScale(domain: priceRange.min...priceRange.max)
            .frame(height: 250)
            
            // 統計資訊
            chartInfo
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // 統計資訊
    private var chartInfo: some View {
        VStack(spacing: 8) {
            if let first = processedData.first, let last = processedData.last {
                let change = last.close - first.open
                let changePercent = first.open > 0 ? (change / first.open) * 100 : 0
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("期間表現")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f") (\(changePercent, specifier: "%.1f")%)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(change >= 0 ? .red : .green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("最新價格")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(last.close, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // 圖例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 12, height: 3)
                    Text("上漲")
                        .font(.caption2)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 12, height: 3)
                    Text("下跌")
                        .font(.caption2)
                }
                
                Spacer()
                
                Text("資料來源: Yahoo Finance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.secondary)
        }
    }
}
