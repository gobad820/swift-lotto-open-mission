//
//  LottoConstants.swift
//  LottoApp
//
//  Created by 김상해 on 11/13/25.
//

import SwiftUI

enum LottoConstants {
    static let slotMachine = "🎰🎰🎰"
    static let lotteryNumberSize : Int = 6
    static let maximumNumber : Int = 45
    
    static let colors : [Color] = [
        .yellow,
        .blue,
        .red,
        .black,
        .green
    ]
    
    static func ballColor(for number: Int)-> Color{
        colors[(number-1)/10]
    }
}
