import Foundation
import SwiftUI
import Combine
import Charts

final class StockElement: AccountingElementBase {
    @Published var price: Double // 當前股價
    @Published var costPrice: Double // 成本價
    var shares: Double // 股數
    var symbol: String // 股票代碼
    
    init(timestamp: Date = Date(), accountName: String = "", shares: Double = 0.0, symbol: String = "", costPrice: Double = 0.0) {
        self.price = 0.0
        self.costPrice = costPrice
        self.shares = shares
        self.symbol = symbol
        super.init()
        self.timestamp = timestamp
        self.accountName = accountName
        self.currency = .USD // 預設貨幣
    }
    
    override func getBalanceAsync(currency: Currency) async -> Double {
        let totalValue = shares * price
        if self.currency == currency {
            return totalValue
        }
        
        let convertedAmount = await Currency.convert(
            amount: totalValue,
            from: self.currency,
            to: currency
        )
        
        return convertedAmount > 0 ? convertedAmount : totalValue
    }
    
    // 成本價值（新增方法）
    func getCostBalanceAsync(currency: Currency) async -> Double {
        let totalCost = shares * costPrice
        if self.currency == currency {
            return totalCost
        }
        
        let convertedAmount = await Currency.convert(
            amount: totalCost,
            from: self.currency,
            to: currency
        )
        
        return convertedAmount > 0 ? convertedAmount : totalCost
    }
    
    override func GetListView() -> AnyView {
        AnyView(StockListView(element: self))
    }
    
    override func GetDetailView() -> AnyView {
        AnyView(StockDetailView(element: self))
    }
    
    // 重新加載股價
    func refreshPrice() async {
        await loadStockPrice()
    }
    
    func loadHistoricalPrices(interval: String = "1d") async -> [KLineData] {
        print("📊 開始加載歷史數據: \(symbol) 間隔: \(interval)")
        let historicalData = await Utilities.fetchStockHistoricalPrices(symbol: symbol)
        
        print("📊 歷史數據加載完成: 收到 \(historicalData.count) 根\(interval)K線")
        
        return historicalData
    }
    // 私有方法：加載股價
    private func loadStockPrice() async {
        let result = await Utilities.fetchStockCurrentPrice(symbol: symbol)
        
        await MainActor.run {
            self.price = result.price
            self.currency = result.currency
            self.objectWillChange.send()
            print("✅ 股票資料加載完成: \(symbol) 價格=\(result.price) 貨幣=\(result.currency.rawValue)")
        }
    }
}

struct StockListView: View {
    @ObservedObject var element: StockElement
    @State private var isLoading = false
    @State private var displayPrice: Double = 0.0
    @State private var displayCurrency: Currency = .USD
    @State private var displayBalance: Double = 0.0
    
    var body: some View {
        HStack {
            // 左邊：股票資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(element.accountName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(element.symbol) • \(element.shares, specifier: "%.0f") 股")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 右邊：金額資訊
            VStack(alignment: .trailing, spacing: 2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(displayCurrency.symbol)\(displayBalance, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(displayBalance >= 0 ? .primary : .red)
                    
                    if displayPrice > 0 {
                        Text("\(displayCurrency.symbol)\(displayPrice, specifier: "%.2f")/股 • \(displayCurrency.rawValue)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("讀取中...")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // 加載股價
        await element.refreshPrice()
        
        // 更新顯示資料
        await MainActor.run {
            displayPrice = element.price
            displayCurrency = element.currency
        }
        
        // 計算餘額
        let balance = await element.getBalanceAsync(currency: element.currency)
        
        await MainActor.run {
            displayBalance = balance
            isLoading = false
        }
    }
}

struct StockDetailView: View {
    @ObservedObject var element: StockElement
    @State private var isLoading = false
    @State private var displayPrice: Double = 0.0
    @State private var displayCurrency: Currency = .USD
    @State private var displayBalance: Double = 0.0
    @State private var kLineData: [KLineData] = []
    @State private var showKLineChart = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 頂部：股票名稱和代碼
                VStack(alignment: .leading, spacing: 8) {
                    Text(element.accountName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(element.symbol)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Text("貨幣: \(displayCurrency.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 中間：總價值顯示
                VStack(spacing: 12) {
                    Text("當前總價值")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Text("\(displayCurrency.symbol)\(displayBalance, specifier: "%.2f")")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(displayBalance >= 0 ? .primary : .red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // K線圖區域
                VStack {
                    Text("除錯資訊: kLineData.count = \(kLineData.count)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    StockKLineChartView(kLineData: kLineData, symbol: element.symbol)
                }
                
                // 詳細資訊
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("持股數量")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(element.shares, specifier: "%.0f") 股")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("當前股價")
                            .foregroundColor(.secondary)
                        Spacer()
                        if displayPrice > 0 {
                            Text("\(displayCurrency.symbol)\(displayPrice, specifier: "%.2f") \(displayCurrency.rawValue)")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        } else {
                            Text("讀取中...")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("成本股價")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(displayCurrency.symbol)\(element.costPrice, specifier: "%.2f") \(displayCurrency.rawValue)")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("貨幣")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(displayCurrency.rawValue)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("創建時間")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(element.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                
                // 操作按鈕
                HStack(spacing: 16) {
                    Button("更新股價") {
                        Task {
                            await refreshPrice()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button(showKLineChart ? "隱藏K線圖" : "顯示K線圖") {
                        withAnimation {
                            showKLineChart.toggle()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("股票詳情")
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // 如果還沒有價格，加載股價
        if element.price == 0 {
            await element.refreshPrice()
        }
        
        // 加載K線數據
        await loadKLineData()
        
        // 更新顯示資料
        await MainActor.run {
            displayPrice = element.price
            displayCurrency = element.currency
        }
        
        // 計算餘額
        let balance = await element.getBalanceAsync(currency: element.currency)
        
        await MainActor.run {
            displayBalance = balance
            isLoading = false
        }
    }
    
    private func refreshPrice() async {
        isLoading = true
        await element.refreshPrice()
        await loadKLineData()
        
        // 更新顯示資料
        await MainActor.run {
            displayPrice = element.price
            displayCurrency = element.currency
        }
        
        // 重新計算餘額
        let balance = await element.getBalanceAsync(currency: element.currency)
        
        await MainActor.run {
            displayBalance = balance
            isLoading = false
        }
    }
    
    private func loadKLineData() async {
        let historicalData = await element.loadHistoricalPrices()
        await MainActor.run {
            self.kLineData = historicalData
        }
    }
}
