//
//  ContentView.swift
//  LottoApp
//
//  Created by 김상해 on 11/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LottoViewModel()
    @State private var inputNumber = ""
    @State private var inputMoney = ""
    @State private var roundNumber = "1197"
    @FocusState private var isInputActive: Bool
    @State private var showChangeAlert = false  // ✅ 잔돈 경고용
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                headerSection
                purchaseSection
                
                // ✅ 티켓이 있을 때만 표시
                if !viewModel.tickets.isEmpty {
                    ticketsSection
                }
                
                fetchWinningSection
                winningInputSection  // ✅ 추가!
                checkResultButton
                
                if viewModel.showResults {
                    resultsSection
                }
            }
            .padding()
        }
        .alert("잔돈 발생", isPresented: $showChangeAlert) {  // ✅ 잔돈 확인
            Button("취소", role: .cancel) {
                inputMoney = ""  // 취소하면 입력 초기화
            }
            Button("구매") {
                completePurchase()
            }
        } message: {
            Text(changeAlertMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack {
            Text(LottoConstants.slotMachine)
                .font(.largeTitle)
            
            Text("복권 번호 생성기")
                .font(.largeTitle)
                .foregroundStyle(.blue)
        }
    }
    
    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 15) {
            Text("복권 구매")
                .font(.headline)
            
            TextField("금액 입력 (1000원 단위)", text: $inputMoney)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused($isInputActive)
            
            // ✅ 실시간 피드백
            purchaseFeedbackView
            
            Button("복권 \(purchaseCount)장 구매") {
                isInputActive = false
                purchaseTickets()
            }
            .buttonStyle(.bordered)
            .disabled(!canPurchase)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // ✅ 구매 피드백 뷰 분리
    @ViewBuilder
    private var purchaseFeedbackView: some View {
        if let money = Int(inputMoney), !inputMoney.isEmpty {
            VStack(spacing: 8) {
                if money < 1000 {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("최소 1000원 이상 입력하세요")
                            .font(.caption)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(money / 1000)장 구매 가능")
                            .font(.caption)
                    }
                    
                    // 잔돈 경고
                    if money % 1000 != 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("잔돈 \(money % 1000)원 발생")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
    
    private var purchaseCount: Int {
        guard let money = Int(inputMoney), money >= 1000 else { return 0 }
        return money / 1000
    }
    
    private var canPurchase: Bool {
        purchaseCount > 0
    }
    
    // ✅ 잔돈 확인 메시지
    private var changeAlertMessage: String {
        guard let money = Int(inputMoney) else { return "" }
        let count = money / 1000
        let change = money % 1000
        return "\(count)장 구매 후 \(change)원이 남습니다.\n그래도 구매하시겠습니까?"
    }
    
    private func purchaseTickets() {
        guard let money = Int(inputMoney), money >= 1000 else { return }
        
        // 잔돈 있으면 확인
        if money % 1000 != 0 {
            showChangeAlert = true
        } else {
            completePurchase()
        }
    }
    
    // ✅ 실제 구매 실행
    private func completePurchase() {
        guard purchaseCount > 0 else { return }
        
        viewModel.generateTickets(count: purchaseCount)
        inputMoney = ""
    }
    
    // MARK: - Tickets Section
    private var ticketsSection: some View {
        VStack(spacing: 15) {
            // ✅ 헤더 추가
            HStack {
                Text("구매한 복권")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.tickets.count)장")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            Divider()
            
            ForEach(viewModel.tickets) { ticket in
                LottoTicketView(
                    ticket: ticket,
                    matchCount: viewModel.showResults ? viewModel.matchCount(for: ticket) : nil
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Fetch Winning Section
    private var fetchWinningSection: some View {
        VStack(spacing: 15) {
            Text("당첨 번호 자동 가져오기")
                .font(.headline)
            
            HStack {
                TextField("회차 입력", text: $roundNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                
                Button("가져오기") {
                    if let round = Int(roundNumber) {
                        Task {
                            await viewModel.fetchWinningData(round: round)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                ProgressView("로딩 중...")
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            if !viewModel.fetchedWinningNumbers.isEmpty {
                VStack(spacing: 8) {
                    Text("가져온 당첨 번호")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(viewModel.fetchedWinningNumbers, id: \.self) { number in
                            LottoBallView(number: number)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Winning Input Section  ✅ 이게 빠져있었어요!
    private var winningInputSection: some View {
        VStack(spacing: 15) {
            Text("당첨 번호 직접 입력")
                .font(.headline)
            
            TextField("복권 당첨 번호를 입력하세요 (공백으로 구분)", text: $inputNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
            
            Button("입력") {
                viewModel.setWinningNumbers(inputNumber)
                inputNumber = ""  // 입력 후 초기화
            }
            .buttonStyle(.bordered)
            .disabled(inputNumber.isEmpty)
            
            if !viewModel.winningNumbers.isEmpty {
                VStack(spacing: 8) {
                    Text("설정된 당첨 번호")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(viewModel.winningNumbers, id: \.self) { number in
                            LottoBallView(number: number)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Check Result Button
    private var checkResultButton: some View {
        Button("당첨 확인") {
            viewModel.showResults = true
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canCheckResult)
        .padding(.top, 10)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(spacing: 15) {
            Text("당첨 결과")
                .font(.title2)
                .bold()
            
            Divider()
            
            ForEach(Array(viewModel.tickets.enumerated()), id: \.element.id) { index, ticket in
                HStack {
                    Text("\(index + 1)번째 티켓")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    let matchCount = viewModel.matchCount(for: ticket)
                    Text("\(matchCount)개 일치")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(resultColor(for: matchCount))
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // ✅ 당첨 개수에 따른 색상
    private func resultColor(for count: Int) -> Color {
        switch count {
        case 6: return .red
        case 5: return .orange
        case 4: return .blue
        case 3: return .green
        default: return .gray
        }
    }
}

#Preview {
    ContentView()
}
