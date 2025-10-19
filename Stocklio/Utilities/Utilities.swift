import Foundation
import SwiftUI
import Combine
final class Utilities {
    
    // MARK: - 股價查詢（帶緩存和 callback）
    
    static func fetchStockCurrentPrice(
        symbol: String,
        useCache: Bool = true,
        success: ((Double, Currency) -> Void)? = nil,
        failure: (() -> Void)? = nil
    ) async -> (price: Double, currency: Currency) {
        
        let cleanSymbol = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        
        // 1. 先檢查緩存
        if useCache, let cached = MainApp.stockPriceCache[cleanSymbol] {
            print("📦 從緩存讀取股價: \(cleanSymbol) = \(cached.price) \(cached.currency.rawValue)")
            success?(cached.price, cached.currency)
            return cached
        }
        
        // 2. 緩存沒有，從網路獲取（帶超時機制）
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)"
        
        guard let url = URL(string: urlString) else {
            failure?()
            return (price: 0.0, currency: .USD)
        }
        
        do {
            // 設定 10 秒超時
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10.0
            let session = URLSession(configuration: configuration)
            
            let (data, _) = try await session.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chart = json["chart"] as? [String: Any],
               let result = chart["result"] as? [[String: Any]],
               let firstResult = result.first,
               let meta = firstResult["meta"] as? [String: Any],
               let price = meta["regularMarketPrice"] as? Double {
                
                // 從 meta 取得幣值
                let currencyString = meta["currency"] as? String ?? "USD"
                let currency = mapYahooCurrencyToAppCurrency(currencyString)
                
                print("🌐 從網路獲取股價成功: \(cleanSymbol) = \(price) \(currency.rawValue)")
                
                // 3. 加入緩存
                MainApp.stockPriceCache[cleanSymbol] = (price, currency)
                
                // 4. 調用成功 callback
                success?(price, currency)
                
                return (price: price, currency: currency)
            } else {
                // 解析失敗
                failure?()
                return (price: 0.0, currency: .USD)
            }
        } catch {
            print("❌ 獲取股價失敗: \(error)")
            failure?()
            return (price: 0.0, currency: .USD)
        }
    }
    
    // MARK: - 匯率查詢（帶緩存和 callback）
    
    static func fetchExchangeRate(
        from fromCurrency: Currency,
        to toCurrency: Currency,
        useCache: Bool = true,
        success: ((Double) -> Void)? = nil,
        failure: (() -> Void)? = nil
    ) async -> Double {
        
        if fromCurrency == toCurrency {
            success?(1.0)
            return 1.0
        }
        
        let cacheKey = "\(fromCurrency.rawValue)-\(toCurrency.rawValue)"
        
        // 1. 先檢查緩存
        if useCache, let cachedRate = MainApp.exchangeRateCache[cacheKey] {
            print("📦 從緩存讀取匯率: \(fromCurrency.rawValue) → \(toCurrency.rawValue) = \(cachedRate)")
            success?(cachedRate)
            return cachedRate
        }
        
        let symbol = "\(fromCurrency.rawValue)\(toCurrency.rawValue)=X"
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)"
        
        guard let url = URL(string: urlString) else {
            failure?()
            return 0.0
        }
        
        do {
            // 設定 10 秒超時
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10.0
            let session = URLSession(configuration: configuration)
            
            let (data, _) = try await session.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chart = json["chart"] as? [String: Any],
               let result = chart["result"] as? [[String: Any]],
               let firstResult = result.first,
               let meta = firstResult["meta"] as? [String: Any],
               let rate = meta["regularMarketPrice"] as? Double {
                
                print("🌐 從網路獲取匯率成功: \(fromCurrency.rawValue) → \(toCurrency.rawValue) = \(rate)")
                
                // 2. 加入緩存
                MainApp.exchangeRateCache[cacheKey] = rate
                
                // 3. 調用成功 callback
                success?(rate)
                
                return rate
            } else {
                // 解析失敗
                failure?()
                return 0.0
            }
        } catch {
            print("❌ 獲取匯率失敗: \(error)")
            failure?()
            return 0.0
        }
    }
    
    // MARK: - 工具方法
    
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
            print("⚠️ 未知幣值: \(yahooCurrency)，使用 USD 作為預設")
            return .USD
        }
    }
    
    static func clearAllCache() {
        MainApp.stockPriceCache.removeAll()
        MainApp.exchangeRateCache.removeAll()
    }
}
