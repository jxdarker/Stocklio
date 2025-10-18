import SwiftUI
import SwiftData

class AccountingElementBase : Identifiable{
    var timestamp: Date
    var accountName: String
    var currency: Currency
    
    init() {
        self.timestamp = Date()
        self.accountName = "Unidentified"
        self.currency = .TWD
    }
    
    // 創建列表視圖
    func GetListView() -> AnyView {
        return AnyView(EmptyView())
    }

    // 創建詳情視圖
    func GetDetailView() -> AnyView {
        return AnyView(EmptyView())
    }

    func GetBalance(currency:Currency) -> Double {
        return Double.nan
    }
    
    func GetBalance() -> Double {
        return GetBalance(currency: self.currency)
    }
}
