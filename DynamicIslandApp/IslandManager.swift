// IslandManager.swift
// Gerencia o estado da ilha: qual atividade está ativa, música tocando,
// bateria carregando, timer, etc. Também escuta o sistema de verdade:
// - Música: MPNowPlayingInfoCenter (Apple Music, Spotify, etc.)
// - Bateria: UIDevice (notificações de carregamento)

import Foundation
import UIKit
import MediaPlayer
import Combine
import UserNotifications
import SwiftUI

enum IslandActivity: Equatable {
    case idle
    case music
    case timer
    case charging
    case faceID
    case airpods
    case call
    case notification
}

struct NowPlayingInfo {
    var title: String = "Nenhuma música"
    var artist: String = ""
    var isPlaying: Bool = false
    var elapsed: Double = 0
    var duration: Double = 0
}

// Uma notificação exibida na ilha (mensagem, lembrete, alerta...)
struct IslandNotification: Identifiable {
    let id = UUID()
    var appName: String
    var title: String
    var body: String
    var date: Date = Date()
    var color: Color
    var icon: String
}

class IslandManager: NSObject, ObservableObject {
    static let shared = IslandManager()

    @Published var activity: IslandActivity = .idle
    @Published var nowPlaying = NowPlayingInfo()
    @Published var batteryLevel: Float = 0
    @Published var isCharging: Bool = false
    @Published var timerRemaining: TimeInterval = 300
    @Published var timerTotal: TimeInterval = 300
    @Published var callSeconds: Int = 0
    @Published var inCall: Bool = false
    @Published var currentNotification: IslandNotification?

    private var timerCancellable: AnyCancellable?
    private var nowPlayingCancellable: AnyCancellable?
    private var callTimer: Timer?
    private var faceIDTimer: Timer?
    private var notificationTimer: Timer?
    private var notificationQueue: [IslandNotification] = []

    private override init() {
        super.init()
        setupNowPlaying()
        setupBattery()
        setupNotifications()
    }

    // MARK: - Música (informações reais do que está tocando)

    private func setupNowPlaying() {
        // O MediaPlayer não expõe notificação confiável para mudanças do
        // Now Playing, então consultamos a cada segundo (polling).
        nowPlayingCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refreshNowPlaying() }
        refreshNowPlaying()
    }

    private func refreshNowPlaying() {
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        nowPlaying.title = info[MPMediaItemPropertyTitle] as? String ?? "Sem título"
        nowPlaying.artist = info[MPMediaItemPropertyArtist] as? String ?? ""
        nowPlaying.elapsed = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double ?? 0
        nowPlaying.duration = info[MPMediaItemPropertyPlaybackDuration] as? Double ?? 0
        // Playback rate: 1.0 = tocando, 0.0 = pausado
        let rate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
        nowPlaying.isPlaying = rate > 0
    }

    // MARK: - Bateria (carregamento real do iPhone)

    private func setupBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refreshBattery()

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshBattery() }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshBattery() }
    }

    private func refreshBattery() {
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = (UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full)
    }

    // MARK: - Ações

    func show(_ newActivity: IslandActivity) {
        stopTimers()
        activity = newActivity

        switch newActivity {
        case .timer:
            timerRemaining = timerTotal
            startTimerCountdown()
        case .faceID:
            // Face ID some sozinho depois de 2.4s
            faceIDTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: false) { [weak self] _ in
                if self?.activity == .faceID { self?.activity = .idle }
            }
        case .call:
            inCall = false
            callSeconds = 0
        default:
            break
        }
    }

    func acceptCall() {
        inCall = true
        callSeconds = 0
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callSeconds += 1
        }
    }

    func endCall() {
        stopTimers()
        activity = .idle
    }

    func togglePlayPause() {
        // Observação: não existe API pública para controlar a música do
        // sistema (play/pause de outro app). O botão alterna o estado
        // local só para a animação da ilha; o polling de 1s sincroniza
        // com o que está tocando de verdade.
        nowPlaying.isPlaying.toggle()
    }

    func skipTrack() {
        // Sem API pública para pular faixa — reinicia o progresso local
        nowPlaying.elapsed = 0
    }

    private func startTimerCountdown() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timerRemaining > 0 {
                    self.timerRemaining -= 1
                } else {
                    self.timerRemaining = self.timerTotal // reinicia
                }
            }
    }

    private func stopTimers() {
        timerCancellable?.cancel()
        callTimer?.invalidate()
        faceIDTimer?.invalidate()
        notificationTimer?.invalidate()
        callTimer = nil
        faceIDTimer = nil
        notificationTimer = nil
        currentNotification = nil
        notificationQueue.removeAll()
    }

    // MARK: - Notificações

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // Pede permissão para notificações locais
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Agenda uma notificação local REAL que dispara em 3 segundos.
    /// Quando ela chega com o app aberto, aparece na ilha.
    func scheduleTestNotification() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Dynamic Island"
        content.body = "Sua notificação de teste chegou! 🎉"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "teste-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Exibe uma notificação na ilha (fila, uma por vez, some em 5s)
    func showNotification(_ notification: IslandNotification) {
        notificationQueue.append(notification)
        if currentNotification == nil {
            showNextNotification()
        }
    }

    func dismissNotification() {
        notificationTimer?.invalidate()
        showNextNotification()
    }

    private func showNextNotification() {
        guard !notificationQueue.isEmpty else {
            currentNotification = nil
            if activity == .notification { activity = .idle }
            return
        }
        currentNotification = notificationQueue.removeFirst()
        activity = .notification
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.showNextNotification()
        }
    }
}

// MARK: - Delegate das notificações (app em primeiro plano)

extension IslandManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        showNotification(IslandNotification(
            appName: "Notificações",
            title: content.title.isEmpty ? "Notificação" : content.title,
            body: content.body,
            color: .orange,
            icon: "bell.fill"
        ))
        // Também mostra o banner do sistema
        completionHandler([.banner, .sound])
    }
}
