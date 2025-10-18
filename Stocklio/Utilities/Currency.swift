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
    
    var exchangeRate: Double {
        // 這裡可以設定匯率，實際應用中應該從網路獲取
        switch self {
        case .TWD: return 1.0
        case .USD: return 31.0  // 1 USD = 31 TWD
        case .JPY: return 0.22  // 1 JPY = 0.22 TWD
        case .EUR: return 34.0  // 1 EUR = 34 TWD
        case .CNY: return 4.3   // 1 CNY = 4.3 TWD
        }
    }
    
    static func convert(amount: Double, from sourceCurrency: Currency, to targetCurrency: Currency) -> Double {
        let rateRatio = targetCurrency.exchangeRate / sourceCurrency.exchangeRate
        return amount * rateRatio
    }
}
