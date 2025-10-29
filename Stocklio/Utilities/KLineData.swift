import Foundation
import SwiftUI
import Combine
import Charts

struct KLineData: Identifiable, Equatable{
    let id = UUID()
    let timestamp: Date
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let volume: Double?
    
    // 計算漲跌（用於顏色判斷）
    var isRising: Bool {
        close >= open
    }
    
    // 計算漲跌幅
    var changePercentage: Double {
        guard open > 0 else { return 0 }
        return (close - open) / open * 100
    }
    
    init(timestamp: Date, open: Double, close: Double, high: Double, low: Double, volume: Double? = nil) {
        self.timestamp = timestamp
        self.open = open
        self.close = close
        self.high = high
        self.low = low
        self.volume = volume
    }
}
