import SwiftUI

struct ContentView: View {
    @Binding var items: [AccountingElementBase]  // 接收 Binding
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(items: $items)  // 繼續傳遞給 MainView
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("賬戶")
                }
                .tag(0)
            
            AnalysisView(items: items)  // 傳遞給 AnalysisView（不需要 Binding）
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("分析")
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
    ContentView(items: .constant([]))
}
