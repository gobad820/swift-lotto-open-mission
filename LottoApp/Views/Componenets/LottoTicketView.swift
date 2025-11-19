//
//  LottoTicketView.swift
//  LottoApp
//
//  Created by 김상해 on 11/13/25.
//

import Foundation
import SwiftUI

struct LottoTicketView: View{
    let ticket: LottoTicket
    let matchCount: Int?
    
    var body: some View{
        VStack(alignment: .leading, spacing: 5) {
                   HStack(spacing: 10) {
                       ForEach(ticket.sortedNumbers, id: \.self) { number in
                           LottoBallView(number: number)
                       }
                   }
                   
                   if let count = matchCount {
                       Text("\(count)개 일치")
                           .font(.title3)
                           .bold()
                           .foregroundStyle(.blue)
                   }
               }
    }
}
