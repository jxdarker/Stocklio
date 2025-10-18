import Foundation
import SwiftUI
import Combine

final class StockElement: AccountingElementBase, ObservableObject {
    @Published var price: Double // 當前股價
    var shares: Double // 股數
    var symbol: String // 股票代碼
    
    init(timestamp: Date = Date(), accountName: String = "", shares: Double = 0.0, symbol: String = "") {
        self.price = 0.0
        self.shares = shares
        self.symbol = symbol
        super.init()
        self.timestamp = timestamp
        self.accountName = accountName
    }
    
    override func GetBalance(currency: Currency) -> Double {
        return Currency.convert(amount: shares * price, from: self.currency, to: currency)
    }
    
    override func GetListView() -> AnyView {
        AnyView(
            StockListView(element: self)
        )
    }
    
    override func GetDetailView() -> AnyView {
        AnyView(
            StockDetailView(element: self)
        )
    }
}

struct StockListView: View {
    @ObservedObject var element: StockElement
    @State private var isLoading = false
    
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
                    Text("$\(element.GetBalance(currency: element.currency), specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(element.GetBalance(currency: element.currency) >= 0 ? .primary : .red)
                    
                    if element.price > 0 {
                        Text("$\(element.price, specifier: "%.2f")/股 • \(element.currency.rawValue)")
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
            await loadStockPrice()
        }
    }
    
    private func loadStockPrice() async {
        // 只有當還沒有股價時才加載
        if element.price == 0 {
            isLoading = true
            let result = await Utilities.fetchStockCurrentPrice(symbol: element.symbol)
            
            await MainActor.run {
                element.price = result.price
                element.currency = result.currency // 更新貨幣資訊
                isLoading = false
            }
        }
    }
}

// 詳情視圖
struct StockDetailView: View {
    @ObservedObject var element: StockElement
    @State private var isLoading = false
    
    var body: some View {
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
                
                Text("貨幣: \(element.currency.rawValue)")
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
                    Text("$\(element.GetBalance(), specifier: "%.2f")")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(element.GetBalance() >= 0 ? .primary : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // 持股詳情
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
                    if element.price > 0 {
                        Text("$\(element.price, specifier: "%.2f") \(element.currency.rawValue)")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else {
                        Text("讀取中...")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Text("貨幣")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(element.currency.rawValue)
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
            
            // 更新按鈕
            Button("更新股價") {
                Task {
                    await updatePrice()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            
            Spacer()
        }
        .padding()
        .navigationTitle("股票詳情")
        .task {
            await loadStockPrice()
        }
    }
    
    private func loadStockPrice() async {
        if element.price == 0 {
            await updatePrice()
        }
    }
    
    private func updatePrice() async {
        isLoading = true
        let result = await Utilities.fetchStockCurrentPrice(symbol: element.symbol)
        
        await MainActor.run {
            element.price = result.price
            element.currency = result.currency // 更新貨幣資訊
            isLoading = false
        }
    }
}
