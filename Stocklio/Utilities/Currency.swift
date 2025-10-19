enum Currency: String, CaseIterable {
    case TWD = "TWD"
    case USD = "USD"
    case JPY = "JPY"
    case EUR = "EUR"
    case CNY = "CNY"
    
    var symbol: String {
        switch self {
        case .TWD: return "NT$"
        case .USD: return "$"
        case .JPY: return "¥"
        case .EUR: return "€"
        case .CNY: return "¥"
        }
    }
    
    // 非同步貨幣轉換
    static func convert(
        amount: Double,
        from sourceCurrency: Currency,
        to targetCurrency: Currency,
        useCache: Bool = true,
        success: ((Double) -> Void)? = nil,
        failure: (() -> Void)? = nil
    ) async -> Double {
        
        if sourceCurrency == targetCurrency {
            success?(amount)
            return amount
        }
        
        // 直接獲取兩種貨幣間的匯率
        let rate = await Utilities.fetchExchangeRate(
            from: sourceCurrency,
            to: targetCurrency,
            useCache: useCache,
            success: { rate in
                let result = amount * rate
                success?(result)
            },
            failure: {
                failure?()
            }
        )
        
        if rate > 0 {
            let result = amount * rate
            return result
        } else {
            failure?()
            return 0.0
        }
    }
    
    // 獲取對另一種貨幣的匯率
    func exchangeRate(
        to targetCurrency: Currency,
        useCache: Bool = true,
        success: ((Double) -> Void)? = nil,
        failure: (() -> Void)? = nil
    ) async -> Double {
        
        if self == targetCurrency {
            success?(1.0)
            return 1.0
        }
        
        return await Utilities.fetchExchangeRate(
            from: self,
            to: targetCurrency,
            useCache: useCache,
            success: { rate in
                success?(rate)
            },
            failure: {
                failure?()
            }
        )
    }
}
