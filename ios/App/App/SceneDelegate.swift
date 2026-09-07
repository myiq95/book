import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        let bridgeVC = CAPBridgeViewController()
        window?.rootViewController = bridgeVC
        window?.makeKeyAndVisible()
        // 서브클래싱 + capacitorDidLoad() 오버라이드 방식이 이 SPM 빌드
        // 조합에서 "cannot find 'bridge' in scope" 컴파일 에러를 일으켜서,
        // 외부에서 인스턴스의 bridge 프로퍼티에 직접 접근하는 더 단순하고
        // 검증된 방식으로 등록한다. makeKeyAndVisible() 시점에 loadView()가
        // 이미 동기적으로 호출돼 bridge가 준비되지만, 만약을 대비해 한 틱
        // 뒤로 미룬다.
        DispatchQueue.main.async {
            bridgeVC.bridge?.registerPluginInstance(TTSPlugin())
        }

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }
}
