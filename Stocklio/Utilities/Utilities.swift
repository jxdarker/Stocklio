import Foundation
import SwiftUI
import Combine

final class Utilities{
    static func fetchStockCurrentPrice(symbol: String) async -> (price: Double, currency: Currency) {
        let cleanSymbol = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)"
        
        guard let url = URL(string: urlString) else {
            return (price: 0.0, currency: .USD) // 預設 USD
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chart = json["chart"] as? [String: Any],
               let result = chart["result"] as? [[String: Any]],
               let firstResult = result.first,
               let meta = firstResult["meta"] as? [String: Any],
               let price = meta["regularMarketPrice"] as? Double {
                
                // 從 meta 取得幣值
                let currencyString = meta["currency"] as? String ?? "USD"
                let currency = mapYahooCurrencyToAppCurrency(currencyString)
                
                print("獲取股價成功: \(symbol) = \(price) \(currency.rawValue)")
                return (price: price, currency: currency)
            }
        } catch {
            print("獲取股價失敗: \(error)")
        }
        
        return (price: 0.0, currency: .USD) // 預設 USD
    }
    
    static func fetchExchangeRate(from fromCurrency: Currency, to toCurrency: Currency) async -> Double {
        if fromCurrency == toCurrency {
            return 1.0
        }
        
        let symbol = "\(fromCurrency.rawValue)\(toCurrency.rawValue)=X"
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)"
        
        guard let url = URL(string: urlString) else {
            return 0.0
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chart = json["chart"] as? [String: Any],
               let result = chart["result"] as? [[String: Any]],
               let firstResult = result.first,
               let meta = firstResult["meta"] as? [String: Any],
               let rate = meta["regularMarketPrice"] as? Double {
                
                print("獲取匯率成功: \(fromCurrency.rawValue) → \(toCurrency.rawValue) = \(rate)")
                return rate
            }
        } catch {
            print("獲取匯率失敗: \(error)")
        }
        
        return 0.0
    }
    
    static func mapYahooCurrencyToAppCurrency(_ yahooCurrency: String) -> Currency {
        switch yahooCurrency.uppercased() {
        case "TWD", "NTD":
            return .TWD
        case "USD":
            return .USD
        case "JPY":
            return .JPY
        case "EUR":
            return .EUR
        case "CNY", "RMB":
            return .CNY
        default:
            print("未知幣值: \(yahooCurrency)，使用 USD 作為預設")
            return .USD
        }
    }

}
