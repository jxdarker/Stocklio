import Foundation
import SwiftUI
import Combine

enum TimeRange: String, CaseIterable {
    case oneMonth = "1個月"
    case threeMonths = "3個月"
    case sixMonths = "6個月"
    case oneYear = "1年"
    
    var dateRange: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}
