import Foundation

struct LottoTicket: Identifiable{
    let id = UUID()
    let numbers: [Int]
    
    var sortedNumbers: [Int]{
        numbers.sorted()
    }
}

