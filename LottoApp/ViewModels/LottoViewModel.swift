import SwiftUI
import Combine

class LottoViewModel: ObservableObject{
    
    @Published var tickets: [LottoTicket] = []
    @Published var winningNumbers: [Int] = []
    @Published var showResults = false
    private let crawler = LottoCrawler()
    
    @Published var fetchedWinningNumbers: [Int] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchWinningData(round: Int) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            if let result = try await crawler.fetchLottoWinningData(round: round) {
                await MainActor.run {
                    self.fetchedWinningNumbers = result.numbers
                    self.winningNumbers = result.numbers
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "당첨 번호를 가져올 수 없습니다: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // 기존 함수 (한 장 생성)
    func generateTicket(){
        var numbers: Set<Int> = []
        while numbers.count < LottoConstants.lotteryNumberSize {
            numbers.insert(Int.random(in: 1...LottoConstants.maximumNumber))
        }
        
        let ticket = LottoTicket(numbers: Array(numbers))
        tickets.append(ticket)
    }
    
    // ✅ 새로 추가: 여러 장 생성
    func generateTickets(count: Int) {
        guard count > 0 else { return }
        
        var newTickets: [LottoTicket] = []
        
        for _ in 0..<count {
            var numbers: Set<Int> = []
            while numbers.count < LottoConstants.lotteryNumberSize {
                numbers.insert(Int.random(in: 1...LottoConstants.maximumNumber))
            }
            
            let ticket = LottoTicket(numbers: Array(numbers))
            newTickets.append(ticket)
        }
        
        // 한 번에 추가 (성능 최적화)
        tickets.append(contentsOf: newTickets)
    }
    
    func setWinningNumbers(_ input: String){
        let numbers = input.components(separatedBy: " ")
            .compactMap {Int($0)}
            .filter{(1...LottoConstants.maximumNumber).contains($0)}
        
        guard numbers.count == LottoConstants.lotteryNumberSize else{return}
        winningNumbers = numbers.sorted()
    }
    
    func matchCount(for ticket: LottoTicket) -> Int{
        guard !winningNumbers.isEmpty else { return 0}
        
        let ticketNumbers = Set(ticket.sortedNumbers)
        let winning = Set(winningNumbers)
        return ticketNumbers.intersection(winning).count
    }
    
    var canCheckResult: Bool{
        !winningNumbers.isEmpty && !tickets.isEmpty
    }
    
}
