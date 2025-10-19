import Foundation
import SwiftUI
import Combine

class AccountingElementBase: ObservableObject, Identifiable {
    @Published var timestamp: Date
    @Published var accountName: String
    @Published var currency: Currency
    
    let id = UUID()
    
    init() {
        self.timestamp = Date()
        self.accountName = ""
        self.currency = .USD
    }
    
    // 非同步版本（推薦使用）
    func getBalanceAsync(currency: Currency) async -> Double {
        return 0.0 // 子類別需要覆寫
    }
    
    func GetListView() -> AnyView {
        return AnyView(EmptyView())
    }
    
    func GetDetailView() -> AnyView {
        return AnyView(EmptyView())
    }
}
