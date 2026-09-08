//
//  TTSPlugin.swift
//  서재 — 네이티브 읽어주기(TTS) 플러그인
//
//  웹 버전(Web Speech API)은 화면이 잠기면 iOS가 강제로 멈춰버려서
//  근본적으로 백그라운드 재생이 불가능하다. 이 플러그인은 iOS 기본
//  읽어주기 엔진(AVSpeechSynthesizer)을 직접 사용하고, 오디오 세션을
//  "재생(playback)" 카테고리로 설정한 뒤 Info.plist의
//  UIBackgroundModes(audio)와 함께 쓰면, 화면이 꺼지거나 잠겨도
//  네이티브 앱이므로 정상적으로 계속 읽어준다.
//
//  요청대로 기능은 최대한 단순하게 유지한다: 문장 단위로 순서대로
//  읽고, 재생/일시정지/재개/정지만 지원한다. 세밀한 문장 하이라이트나
//  건너뛰기 같은 부가 기능은 넣지 않았다.
//
import Foundation
import Capacitor
import AVFoundation

@objc(TTSPlugin)
public class TTSPlugin: CAPPlugin, CAPBridgedPlugin, AVSpeechSynthesizerDelegate {
    public let identifier = "TTSPlugin"
    public let jsName = "TTSPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "speak", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pause", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resume", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setRate", returnType: CAPPluginReturnPromise),
    ]

    private let synthesizer = AVSpeechSynthesizer()
    private var sentences: [String] = []
    private var currentIndex = 0
    private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

    public override func load() {
        synthesizer.delegate = self
        configureAudioSession()
        // 다른 앱이 오디오를 쓰다가 놓아줄 때(인터럽션 종료) 자동 재개
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
    }

    private func configureAudioSession() {
        do {
            // .playback 카테고리 + UIBackgroundModes(audio)가 백그라운드/
            // 잠금화면 재생을 가능하게 하는 핵심 설정이다.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("TTSPlugin: 오디오 세션 설정 실패 - \(error)")
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .ended {
            configureAudioSession()
            if synthesizer.isPaused {
                synthesizer.continueSpeaking()
            }
        }
    }

    @objc func speak(_ call: CAPPluginCall) {
        let text = call.getString("text", "")
        if text.isEmpty {
            call.resolve() // 읽을 내용이 없으면 조용히 통과(단순하게 처리)
            return
        }
        rate = call.getFloat("rate", rate)
        configureAudioSession()
        synthesizer.stopSpeaking(at: .immediate)
        sentences = splitIntoSentences(text)
        currentIndex = 0
        speakCurrent()
        call.resolve()
    }

    @objc func pause(_ call: CAPPluginCall) {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
        call.resolve()
    }

    @objc func resume(_ call: CAPPluginCall) {
        configureAudioSession()
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
        call.resolve()
    }

    @objc func stop(_ call: CAPPluginCall) {
        synthesizer.stopSpeaking(at: .immediate)
        sentences = []
        currentIndex = 0
        call.resolve()
    }

    @objc func setRate(_ call: CAPPluginCall) {
        rate = call.getFloat("rate", rate)
        call.resolve()
    }

    // 아주 단순하게: 마침표/물음표/느낌표/줄바꿈 기준으로만 문장을 나눈다.
    private func splitIntoSentences(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ".!?\n")
        return text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func speakCurrent() {
        guard currentIndex < sentences.count else {
            notifyListeners("finished", data: [:])
            return
        }
        let utterance = AVSpeechUtterance(string: sentences[currentIndex])
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        synthesizer.speak(utterance)
        notifyListeners("boundary", data: [
            "index": currentIndex,
            "total": sentences.count,
            "text": sentences[currentIndex],
        ])
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentIndex += 1
        speakCurrent()
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // stop()으로 명시적으로 취소된 경우이므로 다음 문장으로 넘어가지 않는다.
    }
}
