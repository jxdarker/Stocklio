import Foundation
import SwiftUI
import Combine

final class CashElement: AccountingElementBase {
    @Published var balance: Double
    
    init(timestamp: Date = Date(), accountName: String = "", balance: Double = 0.0) {
        self.balance = balance
        super.init()
        self.timestamp = timestamp
        self.accountName = accountName
    }
    
    override func getBalanceAsync(currency: Currency) async -> Double {
        if self.currency == currency {
            return balance
        }
        
        let convertedAmount = await Currency.convert(
            amount: balance,
            from: self.currency,
            to: currency
        )
        
        return convertedAmount > 0 ? convertedAmount : balance
    }
    
    override func GetListView() -> AnyView {
        AnyView(CashListView(element: self))
    }
    
    override func GetDetailView() -> AnyView {
        AnyView(CashDetailView(element: self))
    }
}

struct CashListView: View {
    @ObservedObject var element: CashElement
    @State private var displayBalance: Double = 0.0
    @State private var displayCurrency: Currency = .USD
    
    var body: some View {
        HStack {
            Text(element.accountName)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(displayCurrency.symbol)\(displayBalance, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(displayCurrency.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .task {
            await updateDisplayBalance()
        }
        .onChange(of: element.balance) { _ in
            Task {
                await updateDisplayBalance()
            }
        }
        .onChange(of: element.currency) { _ in
            Task {
                await updateDisplayBalance()
            }
        }
    }
    
    private func updateDisplayBalance() async {
        let balance = await element.getBalanceAsync(currency: element.currency)
        
        await MainActor.run {
            displayBalance = balance
            displayCurrency = element.currency
        }
    }
}

struct CashDetailView: View {
    @ObservedObject var element: CashElement
    @State private var displayBalance: Double = 0.0
    @State private var displayCurrency: Currency = .USD
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(element.accountName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 詳情頁也把金額放在右邊
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(displayCurrency.symbol)\(displayBalance, specifier: "%.2f")")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("當前餘額 (\(displayCurrency.rawValue))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("原始金額")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(element.currency.symbol)\(element.balance, specifier: "%.2f") \(element.currency.rawValue)")
                        .fontWeight(.medium)
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
                    Text(element.timestamp.formatted(date: .numeric, time: .standard))
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
        }
        .padding()
        .navigationTitle("現金詳情")
        .task {
            await updateDisplayBalance()
        }
        .onChange(of: element.balance) { _ in
            Task {
                await updateDisplayBalance()
            }
        }
        .onChange(of: element.currency) { _ in
            Task {
                await updateDisplayBalance()
            }
        }
    }
    
    private func updateDisplayBalance() async {
        let balance = await element.getBalanceAsync(currency: element.currency)
        
        await MainActor.run {
            displayBalance = balance
            displayCurrency = element.currency
        }
    }
}
