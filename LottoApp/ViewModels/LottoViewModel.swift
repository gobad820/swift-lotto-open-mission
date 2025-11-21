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
    
    @Published var scannedTickets: [LottoTicket] = []
    
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
        !winningNumbers.isEmpty && !scannedTickets.isEmpty
    }
    
    func addTicketFromQR(url: String) {
        print("📷 스캔 감지: \(url)")
       
        let result = parseQRUrl(url)
        let newTickets = result.tickets
        let scannedRound = result.round
        
        if newTickets.isEmpty {
            print("⚠️ 유효하지 않은 로또 QR입니다.")
            return
        }
        
        scannedTickets.insert(contentsOf: newTickets.reversed(), at: 0)
        
        if let round = scannedRound {
            print("\(round)회차 QR 감지 ! 당첨 번호 조회를 시작합니다.")
            
            Task {
                await fetchWinningData(round: round)
            }
        }
    }
    
    private func parseQRUrl(_ url: String) -> (round: Int?,tickets: [LottoTicket] ){
        print("🔍 원본 URL 분석: \(url)")
        
        guard let range = url.range(of: "v=") else { return(nil, []) }
        var dataString = String(url[range.upperBound...])
        
        if dataString.count < 4 { return (nil, []) }
        
        let roundString = String(dataString.prefix(4))
        let round = Int(roundString)
        
        dataString.removeFirst(4)
        
        
        let numberOnlyString = dataString.filter { $0.isNumber }
        
        var parsedTickets: [LottoTicket] = []
        var currentIndex = numberOnlyString.startIndex
        
        while currentIndex < numberOnlyString.endIndex {
            guard let end = numberOnlyString.index(currentIndex, offsetBy: 12, limitedBy: numberOnlyString.endIndex) else { break }
            
            let gameString = String(numberOnlyString[currentIndex..<end])
            let numbers = extractNumbers(from: gameString)
            
            let isValidTicket = numbers.count == 6 &&
            numbers.allSatisfy { $0 >= 1 && $0 <= 45 } &&
            Set(numbers).count == 6
            
            if isValidTicket {
                parsedTickets.append(LottoTicket(numbers: numbers))
            } else {
                print("🗑️ 가짜/더미 데이터 폐기: \(numbers)")
            }
            
            currentIndex = end
        }
        
        return (round, parsedTickets)
    }
    
    private func extractNumbers(from string: String) -> [Int] {
        var result: [Int] = []
        var currentIndex = string.startIndex
        
        while currentIndex < string.endIndex {
            let nextIndex = string.index(currentIndex, offsetBy: 2)
            if nextIndex > string.endIndex { break }
            
            let numberString = string[currentIndex..<nextIndex]
            if let number = Int(numberString) {
                result.append(number)
            }
            
            currentIndex = nextIndex
        }
        return result.sorted()
    }
    
}
