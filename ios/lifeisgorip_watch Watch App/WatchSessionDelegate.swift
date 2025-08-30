//
//  WatchSessionDelegate.swift
//  Runner
//
//  Created by 남윤형 on 8/26/25.
//

import Foundation
import SwiftUI
import WatchConnectivity // iOS ↔ Apple Watch 통신을 위한 프레임워크

struct Routine: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [Exercise]
}

struct Exercise: Identifiable {
    let id = UUID()
    let reps: String
    let weight: String
}

// ObservableObject: SwiftUI에서 데이터 변화를 UI에 반영 가능
// WCSessionDelegate: 워치와의 세션 이벤트를 처리하는 프로토콜
class WatchSessionDelegate: NSObject, ObservableObject, WCSessionDelegate {
    
    // iPhone ↔ Watch 기본 세션 객체
    private let session = WCSession.default
    
    // SwiftUI에서 바인딩 가능한 상태 값
    @Published var log = [String]()              // 로그 기록 (메시지 송수신 기록)
    @Published var receivedContext = [String: Any]() // 받은 컨텍스트 저장
    @Published var routines: [Routine] = [] // 운동 루틴 데이터
//     @Published var routines: [Routine] = [
//             Routine(name: "벤치프레스", exercises: [
//                 Exercise(reps: "10", weight: "60"),
//                 Exercise(reps: "8", weight: "65")
//             ]),
//             Routine(name: "스쿼트", exercises: [
//                 Exercise(reps: "12", weight: "80"),
//                 Exercise(reps: "10", weight: "100")
//             ])
//         ]
    
    override init() {
        super.init()
        // 워치 세션 지원 여부 확인 (일부 기기에서는 지원하지 않음)
        if WCSession.isSupported() {
            session.delegate = self  // 현재 클래스가 세션 이벤트 담당
            session.activate()       // 세션 활성화 (워치와 연결 시도)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    // 세션 활성화 완료 시 호출되는 메서드
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // 여기서는 별도 처리 없음 (성공/실패시 로깅 가능)
    }
    
    // iOS ↔ Watch 간 메시지 수신 처리
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any]
    ) {
        DispatchQueue.main.async {
            if let routineData = message["allRoutineInfo"] as? [[String: Any]] {
                var parsed: [Routine] = []

                for routine in routineData {
                    if let name = routine["name"] as? String,
                       let exercises = routine["exercises"] as? [[String: Any]] {
                        let parsedExercises = exercises.compactMap {
                            Exercise(
                                reps: $0["reps"] as? String ?? "-",
                                weight: $0["weight"] as? String ?? "-"
                            )
                        }
                        parsed.append(Routine(name: name, exercises: parsedExercises))
                    }
                }
                self.routines = parsed
            }

            self.log.append("Received message: \(message)")
        }
    }
    
    // MARK: - Send Message
    
    // iPhone에서 Watch로 메시지 전송
    func sendMessage(_ message: String) {
        let _sendMessage = ["data": message] // 전송할 딕셔너리 형태 데이터
        session.sendMessage(_sendMessage, replyHandler: nil) // 워치로 전송 (응답 없음)
        
        // 로그에 송신 기록 추가
        // (여기서는 sendMessage 함수 자체를 String으로 찍는 오타 가능성 → message 내용이 출력되어야 함)
        log.append("Send message: \(message)")
    }
    
    // 최신 applicationContext(상태 데이터)를 받아와 저장
    func refresh() {
        receivedContext = session.receivedApplicationContext
    }
}
