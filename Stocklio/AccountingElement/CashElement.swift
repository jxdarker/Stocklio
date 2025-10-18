import Foundation
import SwiftUI

final class CashElement : AccountingElementBase{
    
    var balance: Double
    
    init(timestamp: Date = Date(), accountName: String = "", balance: Double = 0.0) {
        self.balance = balance
        super.init()
        self.timestamp = timestamp
        self.accountName = accountName
    }
    
    override func GetListView() -> AnyView {
        AnyView(
            HStack {
                Text(accountName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(balance, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
                .padding(.vertical, 4)
        )
    }
    
    override func GetDetailView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                Text(accountName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 詳情頁也把金額放在右邊
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(balance, specifier: "%.2f")")
                            .font(.system(size: 48, weight: .bold))
                        
                        Text("當前餘額")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("创建时间: \(timestamp.formatted(date: .numeric, time: .standard))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
                .padding()
        )
    }
    
    override func GetBalance(currency:Currency) -> Double {
        return Currency.convert(amount: balance, from: self.currency, to: currency)
    }
}
