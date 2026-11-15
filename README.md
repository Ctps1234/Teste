# Dynamic Island no iPhone 11

Simulação da **Dynamic Island** para o iPhone 11 (que tem notch, não Dynamic Island de verdade).

## O que tem aqui

- **`index.html`** — demonstração interativa: um iPhone 11 desenhado na tela com a ilha simulada funcionando (música, timer, carregamento, Face ID, AirPods e ligação). É só abrir no navegador e tocar nos botões.
- **`DynamicIslandApp/`** — o app de verdade em **Swift/SwiftUI**, com projeto Xcode completo (`DynamicIslandApp.xcodeproj`), pílula flutuante por cima de tudo, música real via `MPNowPlayingInfoCenter` e bateria real via `UIDevice`.
- **`.github/workflows/build-ipa.yml`** — compila o app na nuvem (GitHub Actions) e gera o **`DynamicIslandApp.ipa`** pra você baixar e instalar com Sideloadly/AltStore, sem precisar de Mac.

## Como gerar o .ipa

Veja o passo a passo completo em [`DynamicIslandApp/README.md`](DynamicIslandApp/README.md) — resumo:

1. **Sem Mac (recomendado):** faça push → Actions → *Build IPA* → baixe o artefato `.ipa` → instale com Sideloadly usando seu Apple ID gratuito
2. **Com Mac:** abra o `DynamicIslandApp.xcodeproj` no Xcode → *Product → Archive* → exporta o `.ipa` assinado

## Por que é uma simulação?

A Dynamic Island é hardware: só existe no iPhone 14 Pro ou superior. O iPhone 11 tem o notch. Os apps da App Store que "trazem a Dynamic Island" para iPhones com notch fazem o mesmo truque deste projeto: uma janela transparente com uma pílula preta flutuante sobre o notch que expande para mostrar atividades ao vivo.
