import SwiftUI

struct ContentView: View {
    @Binding var items: [AccountingElementBase]
    @Binding var groups: [Group]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(items: $items)
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("賬戶")
                }
                .tag(0)
            
            GroupView(items: items, groups: $groups)
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("組合")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView(items: .constant([]), groups: .constant([]))
}
