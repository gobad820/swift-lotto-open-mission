//
//  LottoCrawler.swift
//  LottoApp
//
//  Created by 김상해 on 11/14/25.
//

import Foundation
import SwiftSoup

class LottoCrawler {
    func fetchLottoWinningData(round: Int) async throws -> LottoResult? {
        print("크롤링 시작: \(round)회차")
        
        let urlString = "https://dhlottery.co.kr/gameResult.do?method=byWin&drwNo=\(round)"
        print("URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("URL 생성 실패")
            throw CrawlerError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("상태 코드: \(httpResponse.statusCode)")
            }
            
            print("받은 데이터 크기: \(data.count) bytes")
            
            let encoding = CFStringConvertEncodingToNSStringEncoding(0x0940)
            guard let html = String(data: data, encoding: String.Encoding(rawValue: encoding)) else {
                print("EUC-KR 디코딩 실패")
                throw CrawlerError.decodingFailed
            }
            
            print("HTML 길이: \(html.count)")
            print("HTML 미리보기:\n\(html.prefix(500))")
            
            guard let result = parseLottoResult(html: html) else {
                print("HTML 파싱 실패")
                throw CrawlerError.parsingFailed
            }
            
            print("파싱 성공!")
            print("회차: \(result.round)")
            print("추첨일: \(result.drawDate)")
            print("당첨번호: \(result.numbers)")
            print("보너스: \(result.bonusNumber)")
            print("1등 당첨자 수: \(result.winnerCounts[1] ?? 0)명")
            print("2등 당첨자 수: \(result.winnerCounts[2] ?? 0)명")
            print("3등 당첨자 수: \(result.winnerCounts[3] ?? 0)명")
            print("4등 당첨자 수: \(result.winnerCounts[4] ?? 0)명")
            print("5등 당첨자 수: \(result.winnerCounts[5] ?? 0)명")

            return result
            
        } catch {
            print("에러 발생: \(error)")
            print("에러 타입: \(type(of: error))")
            throw error
        }
    }
    
    private func parseLottoResult(html: String) -> LottoResult? {
        do {
            let doc = try SwiftSoup.parse(html)
            
            guard let roundText = try doc.select("div.win_result h4 strong").first()?.text(),
                  let round = Int(roundText.replacingOccurrences(of: "회", with: "")) else {
                return nil
            }
            
            guard let dateText = try doc.select("div.win_result p.desc").first()?.text() else {
                return nil
            }
            let drawDate = dateText
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: " 추첨)", with: "")
            
            let numberElements = try doc.select("div.num.win span.ball_645")
            let numbers = numberElements.compactMap { element -> Int? in
                guard let numberText = try? element.text() else { return nil }
                return Int(numberText)
            }
            
            guard let bonusElement = try doc.select("div.num.bonus span.ball_645").first(),
                  let bonusText = try? bonusElement.text(),
                  let bonusNumber = Int(bonusText) else {
                return nil
            }
            
            var winnerCounts: [Int: Int] = [:]
            let rows = try doc.select("table.tbl_data tbody tr")
            
            for (index, row) in rows.enumerated() {
                let rank = index + 1
                
                if let countCell = try? row.select("td").get(2),
                   let countText = try? countCell.text(),
                   let count = Int(countText.replacingOccurrences(of: ",", with: "")) {
                    winnerCounts[rank] = count
                }
            }
            
            guard let salesElements = try? doc.select("ul.list_text_common li"),
                  salesElements.count > 0 else {
                return nil
            }
            
            var totalSales = ""
            for element in salesElements {
                if let text = try? element.text(),
                   text.contains("총판매금액") {
                    totalSales = text
                        .replacingOccurrences(of: "총판매금액 : ", with: "")
                        .replacingOccurrences(of: "원", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            
            return LottoResult(
                round: round,
                numbers: numbers,
                drawDate: drawDate,
                bonusNumber: bonusNumber,
                winnerCounts: winnerCounts,
                totalSales: totalSales
            )
            
        } catch {
            print("파싱 에러: \(error)")
            return nil
        }
    }
}
private func extractWinningNumbers(from doc: Document) throws -> [Int] {
    var numbers: [Int] = []
    
    let ballElements = try doc.select(".ball_645")
    
    for element in ballElements {
        if let numText = try? element.text(),
           let num = Int(numText) {
            numbers.append(num)
        }
    }
    
    if numbers.count > 6 {
        numbers = Array(numbers.prefix(6))
    }
    
    return numbers
}

private func extractBonusNumber(from doc: Document) throws -> Int {
    if let bonusElement = try doc.select(".bonus .ball_645").first(),
       let bonusText = try? bonusElement.text(),
       let bonusNum = Int(bonusText) {
        return bonusNum
    }
    return 0
}

enum CrawlerError: Error {
    case invalidURL
    case decodingFailed
    case parsingFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .decodingFailed:
            return "데이터 변환 실패"
        case .parsingFailed:
            return "HTML 파싱 실패"
        }
    }
}
