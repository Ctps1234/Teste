# Dynamic Island no iPhone 11 — App Swift

Simulação da **Dynamic Island** para iPhones com notch (iPhone 11, XR, X, XS, etc.).

> ⚠️ **Importante:** o iPhone 11 não tem a Dynamic Island de verdade — ela só existe no hardware do iPhone 14 Pro em diante. Este app **simula** a ilha com uma pílula preta flutuante sobre o notch, exatamente como os apps da App Store fazem. A pílula expande para mostrar atividades ao vivo: música, timer, bateria, Face ID, AirPods e ligação.

## O que o app faz

- **Música** — mostra o que está tocando de verdade (Apple Music, Spotify, etc.) via `MPNowPlayingInfoCenter`, com waveform animado, progresso e controles play/pause
- **Timer** — contagem regressiva com anel de progresso
- **Carregando** — reflete o nível real da bateria do iPhone (`UIDevice`)
- **Face ID** — animação de desbloqueio que some sozinha
- **AirPods** — status de conexão
- **Ligação** — simulação de chamada recebida, com atender/recusar
- A ilha fica **por cima de qualquer app** (janela com nível `.alert + 1`) e os toques passam por ela, exceto na própria pílula

## Arquivos

| Arquivo | O que é |
|---|---|
| `DynamicIslandApp.swift` | Ponto de entrada + janela flutuante transparente (o "truque" da simulação) |
| `IslandManager.swift` | Estado da ilha + integração com música real e bateria real |
| `IslandView.swift` | A pílula em SwiftUI: compacta e expandida, com todas as atividades |
| `ContentView.swift` | Tela do app com os botões para testar cada atividade |
| `DynamicIslandApp.xcodeproj/` | **Projeto Xcode completo** — é só abrir e compilar |
| `Assets.xcassets/` | Ícone e cor de destaque do app |

## Como gerar o .ipa (app instalável)

> ℹ️ Um `.ipa` precisa ser **compilado no macOS (Xcode)** e **assinado** com um certificado Apple vinculado ao seu Apple ID. Por isso o .ipa não pode ser gerado num ambiente Linux — mas você tem 3 caminhos abaixo, do mais fácil ao mais completo.

### Opção A — Sem Mac: compilar na nuvem (GitHub Actions) ⭐ recomendado

Este repositório já tem o workflow `.github/workflows/build-ipa.yml`, que compila o app num Mac virtual do GitHub e gera o `DynamicIslandApp.ipa`:

1. Faça **push** deste branch para o GitHub
2. Vá em **Actions → Build IPA → Run workflow** (ou aguarde o push disparar sozinho)
3. Na página do workflow, baixe o artefato **`DynamicIslandApp-ipa`**
4. Instale no iPhone com o **[Sideloadly](https://sideloadly.com/)** (Windows ou Mac) ou **AltStore**, usando seu **Apple ID gratuito** — eles assinam o .ipa e instalam por você

> Com Apple ID gratuito, a assinatura vale **7 dias** (máximo 3 apps). Depois é só reinstalar pelo Sideloadly/AltStore. Para assinatura de 1 ano, é preciso a conta paga do Apple Developer Program (US$ 99/ano).

### Opção B — Com Mac: Xcode (instala direto e gera o .ipa assinado)

1. Abra o **`DynamicIslandApp.xcodeproj`** no Xcode
2. Selecione o projeto → aba **Signing & Capabilities** → marque *Automatically manage signing* e escolha seu **Team** (pode ser um Apple ID gratuito)
3. Conecte o iPhone 11 no Mac, selecione ele no topo do Xcode e aperte **Run** ▶️ — o app instala direto no celular
4. Para gerar o **.ipa assinado**: *Product → Archive* → *Distribute App → Development* → *Export* → salva o `DynamicIslandApp.ipa`

### Opção C — Swift Playgrounds (iPad ou Mac, sem .ipa)

1. Crie um novo **App** no Swift Playgrounds
2. Copie o conteúdo de `ContentView.swift`, `IslandManager.swift` e `IslandView.swift` para o arquivo principal
3. ⚠️ O Swift Playgrounds **não suporta** a janela flutuante (`UIWindow` com nível alto) — a ilha só aparece dentro da tela do app, não por cima de outros apps. Para a experiência completa, use a Opção A ou B.

## Requisitos

- iOS 16 ou superior (o iPhone 11 vai até o iOS 18)
- Xcode 15 ou superior (para as Opções A e B)
- Funciona melhor em iPhones com notch (11, XR, X, XS, etc.)
- Em iPhones com Dynamic Island real (14 Pro+), a pílula fica logo abaixo da ilha de verdade

## Limitações conhecidas

- A simulação não substitui a Dynamic Island real: não há integração com Live Activities do sistema nem com o hardware
- O Face ID e a ligação são animações de demonstração (não disparam o Face ID real nem recebem ligações)
- A música é real: o app lê o `NowPlaying` do sistema, então funciona com qualquer app de música
