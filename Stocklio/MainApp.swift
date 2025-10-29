import SwiftUI

@main
struct MainApp: App {
    
    @State private var groups: [AccountingGroup] = []
    @State var items: [AccountingElementBase] = []
    
    static var stockPriceCache: [String: (price: Double, currency:Currency)] = [:]
    static var exchangeRateCache: [String: Double] = [:] // key: "USD-TWD"
    var body: some Scene {
        WindowGroup {
            ContentView(items: $items, groups: $groups) 
        }
    }
}
