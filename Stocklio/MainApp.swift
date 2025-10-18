import SwiftUI

@main
struct MainApp: App {
    @State var items: [AccountingElementBase] = []
    
    var body: some Scene {
        WindowGroup {
            ContentView(items: $items) 
        }
    }
}
