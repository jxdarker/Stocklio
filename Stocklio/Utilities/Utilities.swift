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
    
    static func fetchStockHistoricalPrices(symbol: String) async -> [KLineData] {
        let cleanSymbol = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(cleanSymbol)?range=1y&interval=1d"
        
        print("🔍 請求歷史數據 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 無效的URL")
            return []
        }
        
        do {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15.0
            let session = URLSession(configuration: configuration)
            
            print("🌐 開始網路請求...")
            let (data, response) = try await session.data(from: url)
            print("🌐 網路請求完成")
            
            // 檢查 HTTP 響應
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP 狀態碼: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ HTTP 錯誤: \(httpResponse.statusCode)")
                    // 嘗試讀取錯誤訊息
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("📄 錯誤內容: \(errorString.prefix(200))...")
                    }
                    return []
                }
            }
            
            print("📦 收到數據大小: \(data.count) bytes")
            
            // 嘗試解析 JSON
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ JSON 解析失敗 - 無效的 JSON 格式")
                return []
            }
            
            print("✅ JSON 解析成功")
            
            // 檢查 chart 欄位
            guard let chart = json["chart"] as? [String: Any] else {
                print("❌ 缺少 'chart' 欄位")
                print("📄 JSON 鍵: \(json.keys)")
                return []
            }
            
            // 檢查 result 欄位
            guard let result = chart["result"] as? [[String: Any]], let firstResult = result.first else {
                print("❌ 缺少 'result' 欄位或為空")
                return []
            }
            
            // 檢查錯誤訊息
            if let error = firstResult["error"] as? [String: Any] {
                print("❌ Yahoo Finance 返回錯誤: \(error)")
                return []
            }
            
            // 檢查 indicators
            guard let indicators = firstResult["indicators"] as? [String: Any],
                  let quote = indicators["quote"] as? [[String: Any]],
                  let firstQuote = quote.first else {
                print("❌ 缺少 indicators 或 quote 數據")
                return []
            }
            
            // 檢查時間戳和價格數據
            guard let timestamps = firstResult["timestamp"] as? [TimeInterval],
                  let opens = firstQuote["open"] as? [Double],
                  let highs = firstQuote["high"] as? [Double],
                  let lows = firstQuote["low"] as? [Double],
                  let closes = firstQuote["close"] as? [Double] else {
                print("❌ 缺少價格或時間數據")
                return []
            }
            
            print("📊 數據統計:")
            print("   - 時間戳數量: \(timestamps.count)")
            print("   - 開盤價數量: \(opens.count)")
            print("   - 最高價數量: \(highs.count)")
            print("   - 最低價數量: \(lows.count)")
            print("   - 收盤價數量: \(closes.count)")
            
            var kLineData: [KLineData] = []
            var validCount = 0
            
            for i in 0..<timestamps.count {
                let timestamp = Date(timeIntervalSince1970: timestamps[i])
                let open = opens[i]
                let high = highs[i]
                let low = lows[i]
                let close = closes[i]
                let volume = (firstQuote["volume"] as? [Double])?[i]
                
                // 跳過無效數據
                guard !open.isNaN, !high.isNaN, !low.isNaN, !close.isNaN,
                      open > 0, high > 0, low > 0, close > 0 else {
                    continue
                }
                
                let kLine = KLineData(
                    timestamp: timestamp,
                    open: open,
                    close: close,
                    high: high,
                    low: low,
                    volume: volume
                )
                kLineData.append(kLine)
                validCount += 1
            }
            
            print("✅ 成功解析 \(validCount)/\(timestamps.count) 根有效K線")
            
            if kLineData.isEmpty {
                print("⚠️ 警告: 沒有有效的K線數據")
                return []
            }
            
            let sortedData = kLineData.sorted(by: { $0.timestamp < $1.timestamp })
            print("📅 數據範圍: \(sortedData.first?.timestamp ?? Date()) 到 \(sortedData.last?.timestamp ?? Date())")
            
            return sortedData
            
        } catch {
            print("❌ 網路請求失敗: \(error.localizedDescription)")
            return []
        }
    }
}
