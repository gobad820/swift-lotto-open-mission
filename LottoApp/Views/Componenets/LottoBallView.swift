import SwiftUI

struct LottoBallView: View{
    let number:Int
    
    var body: some View{
        Text("\(number)")
            .font(.title2)
            .fontWeight(.bold)
            .frame(width: 45, height: 45)
            .background(LottoConstants.ballColor(for: number))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}
