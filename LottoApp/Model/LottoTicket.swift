//
//  LottoNumbers.swift
//  LottoApp
//
//  Created by  on 11/13/25.
//

import Foundation

struct LottoTicket: Identifiable{
    let id = UUID()
    let numbers: [Int]
    
    var sortedNumbers: [Int]{
        numbers.sorted()
    }
}

