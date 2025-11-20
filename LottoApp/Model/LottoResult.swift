//
//  LottoResult.swift
//  LottoApp
//
//  Created by 김상해 on 11/14/25.
//

import Foundation
import SwiftUI

struct LottoResult : Identifiable{
    let id = UUID()
    let round: Int
    let numbers: [Int]
    let drawDate: String
    let bonusNumber: Int
    let winnerCounts: [Int: Int]  // 등수별 당첨 인원 추가
    let totalSales: String
    
//    let firstWinners: Int
//    let firstPrize: Int
//    
//    let secondWinners: Int
//    let secondPrize: Int
//    
//    let thirdWinners: Int
//    let thirdPrize: Int
//    
//    let fourthWInners:Int
//    let fifthWinners: Int
}
