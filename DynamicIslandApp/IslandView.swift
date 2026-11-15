// IslandView.swift
// A interface da pílula: estado compacto (só a pílula) e expandido
// (com o conteúdo da atividade ao vivo). A animação usa spring,
// igual à Dynamic Island real.

import SwiftUI

struct IslandView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        // Preenche todo o frame que o IslandHostingController define
        // (122x34 compacto, 348x100 expandido — animado com spring no UIKit)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.black)
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 4)
            .overlay(
                Group {
                    if manager.activity == .idle {
                        CompactContent()
                    } else {
                        ExpandedContent()
                    }
                }
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: manager.activity)
    }

    private var cornerRadius: CGFloat {
        manager.activity == .idle ? 17 : 32
    }
}

// MARK: - Estado compacto (só a pílula com a câmera)

struct CompactContent: View {
    var body: some View {
        HStack {
            Spacer()
            // "câmera" da ilha, como na Dynamic Island real
            Circle()
                .fill(Color(red: 0.08, green: 0.10, blue: 0.16))
                .frame(width: 10, height: 10)
                .overlay(Circle().fill(Color.blue.opacity(0.35)).frame(width: 4, height: 4).offset(x: -1, y: -1))
                .padding(.trailing, 14)
        }
    }
}

// MARK: - Estado expandido (conteúdo da atividade)

struct ExpandedContent: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        Group {
            switch manager.activity {
            case .music: MusicActivityView()
            case .timer: TimerActivityView()
            case .charging: ChargingActivityView()
            case .faceID: FaceIDActivityView()
            case .airpods: AirPodsActivityView()
            case .call: CallActivityView()
            case .notification: NotificationActivityView()
            case .idle: EmptyView()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Música

struct MusicActivityView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(colors: [.orange, .red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "music.note").foregroundColor(.white).font(.title3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.nowPlaying.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(manager.nowPlaying.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
                WaveformView(isPlaying: manager.nowPlaying.isPlaying)
            }

            // barra de progresso
            ProgressView(value: progress)
                .tint(.white)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
                .frame(height: 3.5)

            HStack(spacing: 28) {
                Button { manager.skipTrack() } label: {
                    Image(systemName: "backward.fill").foregroundColor(.white).font(.title3)
                }
                Button { manager.togglePlayPause() } label: {
                    Image(systemName: manager.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.white).font(.title2)
                }
                Button { manager.skipTrack() } label: {
                    Image(systemName: "forward.fill").foregroundColor(.white).font(.title3)
                }
            }
        }
    }

    private var progress: Double {
        guard manager.nowPlaying.duration > 0 else { return 0 }
        return manager.nowPlaying.elapsed / manager.nowPlaying.duration
    }
}

struct WaveformView: View {
    var isPlaying: Bool
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 3.5, height: animating && isPlaying ? CGFloat.random(in: 6...20) : 5)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: animating)
            }
        }
        .frame(height: 22)
        .onAppear { animating = true }
    }
}

// MARK: - Timer

struct TimerActivityView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 42, height: 42)
                .background(Color.orange.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Timer").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text("termina em").font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()

            Text(formatTime(manager.timerRemaining))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 4).frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: timerFraction)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: manager.timerRemaining)
            }
        }
    }

    private var timerFraction: Double {
        guard manager.timerTotal > 0 else { return 0 }
        return 1 - (manager.timerRemaining / manager.timerTotal)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }
}

// MARK: - Carregando

struct ChargingActivityView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.white.opacity(0.55), lineWidth: 2)
                    .frame(width: 46, height: 24)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: 38 * CGFloat(manager.batteryLevel), height: 18)
                    .offset(x: -19 + 19 * CGFloat(manager.batteryLevel))
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(width: 52, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("Carregando").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text("bateria").font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()

            Text("\(Int(manager.batteryLevel * 100))%")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Face ID

struct FaceIDActivityView: View {
    @State private var scanning = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "faceid")
                .font(.system(size: 34))
                .foregroundColor(.blue)
                .scaleEffect(scanning ? 1.06 : 0.94)
                .opacity(scanning ? 1 : 0.6)
                .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: scanning)
            Text("Face ID")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
        }
        .onAppear { scanning = true }
    }
}

// MARK: - AirPods

struct AirPodsActivityView: View {
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "airpodspro")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 42, height: 42)
                .background(Color.purple.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("AirPods Pro").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text("Conectado · bateria 92%").font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()

            Text("92%")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
        }
    }
}

// MARK: - Ligação

struct CallActivityView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 46, height: 46)
                .overlay(Text("M").font(.title3.bold()).foregroundColor(.white))

            VStack(alignment: .leading, spacing: 2) {
                Text("Maria Silva").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text(manager.inCall ? "em ligação \(formatTime(manager.callSeconds))" : "ligação de iPhone...")
                    .font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()

            if manager.inCall {
                Button { manager.endCall() } label: {
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            } else {
                Button { manager.endCall() } label: {
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                Button { manager.acceptCall() } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

// MARK: - Notificação

struct NotificationActivityView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        if let notification = manager.currentNotification {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(notification.color)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: notification.icon)
                            .foregroundColor(.white)
                            .font(.title3)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(notification.appName.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("agora")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(notification.body)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .contentShape(Rectangle)
            .onTapGesture { manager.dismissNotification() }
        }
    }
}
