// ContentView.swift
// Tela principal do app: botões para testar cada atividade da ilha.
// A ilha flutuante aparece por cima de tudo (inclusive desta tela).

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: IslandManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    activitiesSection
                    infoSection
                }
                .padding(20)
            }
            .navigationTitle("Dynamic Island")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.righthalf.inset.filled")
                .font(.system(size: 44))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Simulação da Dynamic Island no iPhone 11")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("O iPhone 11 tem notch, então a ilha é uma pílula flutuante sobre ele — igual aos apps da App Store. Toque nos botões abaixo e veja a ilha expandir no topo da tela.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Botões das atividades

    private var activitiesSection: some View {
        VStack(spacing: 12) {
            activityButton(icon: "music.note", color: .pink, title: "Música", activity: .music)
            activityButton(icon: "timer", color: .orange, title: "Timer", activity: .timer)
            activityButton(icon: "bolt.fill", color: .green, title: "Carregando", activity: .charging)
            activityButton(icon: "faceid", color: .blue, title: "Face ID", activity: .faceID)
            activityButton(icon: "airpodspro", color: .purple, title: "AirPods", activity: .airpods)
            activityButton(icon: "phone.fill", color: .cyan, title: "Ligação", activity: .call)

            Button {
                manager.show(.idle)
            } label: {
                Text("Voltar ao normal")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func activityButton(icon: String, color: Color, title: String, activity: IslandActivity) -> some View {
        Button {
            manager.show(activity)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 38, height: 38)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Informações

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("A música mostra o que está tocando de verdade (Apple Music, Spotify...)", systemImage: "info.circle")
            Label("A bateria reflete o carregamento real do iPhone", systemImage: "battery.75")
            Label("A ilha fica por cima de qualquer app — toque nela para interagir", systemImage: "hand.tap")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}
