
import Foundation
import SwiftUI
import Combine

struct AddGroupView: View {
    @Environment(\.dismiss) var dismiss
    var onCreateGroup: (String) -> Void
    
    @State private var groupName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("群組名稱")) {
                    TextField("輸入群組名稱", text: $groupName)
                }
            }
            .navigationTitle("新增群組")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("建立") {
                    onCreateGroup(groupName)
                    dismiss()
                }
                .disabled(groupName.isEmpty)
            )
        }
    }
}
