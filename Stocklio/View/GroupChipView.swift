import SwiftUI

struct GroupChipView: View {
    let group: AccountingGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 14))
                
                Text(group.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(group.items.count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(Color.blue, lineWidth: isSelected ? 0 : 1)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}
