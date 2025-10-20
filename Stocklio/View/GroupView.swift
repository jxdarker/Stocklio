import SwiftUI

struct GroupView: View {
    let items: [AccountingElementBase]  // 所有項目
    @Binding var groups: [Group]        // 所有群組
    
    @State private var selectedGroupID: UUID?
    @State private var showAddGroupView = false
    
    // 當前選中的群組
    private var selectedGroup: Group? {
        groups.first { $0.id == selectedGroupID }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 群組選擇器
                groupPickerSection
                
                // 內容區域
                if let selectedGroup = selectedGroup {
                    AnalysisView(group: selectedGroup)
                } else {
                    ContentUnavailableView(
                        "選擇群組",
                        systemImage: "folder",
                        description: Text("請從上方選擇一個群組")
                    )
                }
            }
            .navigationTitle("投資組合")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddGroupView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddGroupView) {
                AddGroupView { groupName in
                    let newGroup = Group(name: groupName)
                    groups.append(newGroup)
                    selectedGroupID = newGroup.id
                }
            }
            .onAppear {
                // 如果沒有選中的群組，選擇第一個
                if selectedGroupID == nil, let firstGroup = groups.first {
                    selectedGroupID = firstGroup.id
                }
            }
        }
    }
    
    private var groupPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(groups) { group in
                    GroupChipView(
                        group: group,
                        isSelected: selectedGroupID == group.id
                    ) {
                        selectedGroupID = group.id
                    }
                    .contextMenu {
                        if group.name != "所有項目" {
                            Button(role: .destructive) {
                                deleteGroup(group)
                            } label: {
                                Label("刪除群組", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
        // 如果刪除的是當前選中的群組，選擇第一個群組
        if selectedGroupID == group.id {
            selectedGroupID = groups.first?.id
        }
    }
}
