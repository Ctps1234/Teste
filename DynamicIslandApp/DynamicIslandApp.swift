// DynamicIslandApp.swift
// App que simula a Dynamic Island no iPhone 11 (que tem notch).
//
// Como funciona:
// - Cria uma janela transparente (UIWindow) com nível acima de tudo (.alert + 1)
// - Só a "pílula" preta é desenhada; o resto da janela é invisível
// - A janela ignora toques, EXCETO na própria pílula (hitTest customizado)
// - A pílula expande/recolhe com animação elástica (spring) igual à Dynamic Island real

import SwiftUI
import UIKit
import Combine

@main
struct DynamicIslandApp: App {
    // Precisamos do AppDelegate para criar a janela flutuante
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var overlayWindow: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Cria a janela da ilha flutuante
        let window = PassthroughWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1          // acima de tudo, inclusive do notch
        window.isHidden = false
        window.rootViewController = IslandHostingController(
            rootView: IslandView()
                .environmentObject(IslandManager.shared),
            manager: IslandManager.shared
        )
        overlayWindow = window
        return true
    }
}

// Janela que deixa os toques passarem por ela, exceto na pílula
class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hosting = rootViewController as? IslandHostingController else { return nil }

        // Converte o ponto para as coordenadas da pílula
        let islandPoint = hosting.islandView.convert(point, from: self)

        // Se o toque caiu dentro da pílula, entrega para a ilha.
        // Caso contrário, ignora (toque passa para o app de baixo).
        if hosting.islandView.bounds.contains(islandPoint) {
            return super.hitTest(point, with: event)
        }
        return nil
    }
}

// ViewController que só ocupa a área da pílula (topo, centralizada)
// e redimensiona a pílula com animação elástica quando a atividade muda
class IslandHostingController: UIViewController {
    let islandView: UIView
    let manager: IslandManager
    private var cancellables = Set<AnyCancellable>()

    init(rootView: some View, manager: IslandManager) {
        self.manager = manager
        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = .clear
        self.islandView = hosting.view
        super.init(nibName: nil, bundle: nil)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // Quando a atividade muda, redimensiona a pílula com spring
        manager.$activity
            .sink { [weak self] _ in self?.layoutIsland(animated: true) }
            .store(in: &cancellables)

        layoutIsland(animated: false)
    }

    private func layoutIsland(animated: Bool) {
        let size: CGSize = manager.activity == .idle
            ? CGSize(width: 122, height: 34)
            : CGSize(width: 348, height: 100)
        let frame = CGRect(
            x: (view.bounds.width - size.width) / 2,
            y: 24, // logo abaixo do notch do iPhone 11
            width: size.width,
            height: size.height
        )
        if animated {
            UIView.animate(
                withDuration: 0.55, delay: 0,
                usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2,
                options: .allowUserInteraction
            ) {
                self.islandView.frame = frame
            }
        } else {
            islandView.frame = frame
        }
    }
}
