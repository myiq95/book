//
//  MainViewController.swift
//  서재
//
//  기본 CAPBridgeViewController는 앱 프로젝트 안에 직접 추가한(=npm
//  패키지가 아닌) 로컬 플러그인을 자동으로 찾아 등록해주지 않는다.
//  TTSPlugin이 CAPBridgedPlugin을 준수하는 것만으로는 부족하고,
//  브릿지가 준비된 시점에 registerPluginInstance로 명시적으로
//  등록해줘야 window.Capacitor.Plugins.TTSPlugin이 실제로 생긴다.
//
import UIKit
import Capacitor

class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(TTSPlugin())
    }
}
