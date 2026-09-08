//
//  MainViewController.swift
//  서재
//
//  Main.storyboard의 "Bridge View Controller" 씬이 기본 CAPBridgeViewController
//  대신 이 클래스를 쓰도록 customClass를 바꿔뒀다. 앱 프로젝트 안에 직접 추가한
//  로컬 플러그인(TTSPlugin)은 npm 패키지가 아니라서 자동 등록되지 않으므로,
//  브릿지가 준비되는 시점(capacitorDidLoad)에 명시적으로 등록해준다.
//
import UIKit
import Capacitor

class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(TTSPlugin())
    }
}
