import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void

    var body: some View {
        ZStack {
            CaltrackTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 86, height: 86)
                            .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                            .shadow(color: CaltrackTheme.green.opacity(0.22), radius: 28)
                        Text("Caltrack")
                            .font(.largeTitle.weight(.black))
                        Text("Tu dieta, cuerpo y entrenamiento, sin ruido")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text("Todo queda en tu iPhone. Tú decides cuándo conectar Salud, Hevy o Grok.")
                            .font(.subheadline)
                            .foregroundStyle(CaltrackTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        feature(icon: "camera.fill", color: CaltrackTheme.green, title: "Foto y listo", text: "Grok estima el plato. Tú revisas y confirmas.")
                        feature(icon: "scope", color: CaltrackTheme.green, title: "Plan adaptativo", text: "Cierra el día y revisa cada semana una propuesta basada en tu tendencia real.")
                        feature(icon: "chart.xyaxis.line", color: CaltrackTheme.blue, title: "Tendencias útiles", text: "Progreso, balance y entrenador basados en datos acumulados.")
                    }

                    Button(action: complete) {
                        Text("Empezar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.black)
                            .background(CaltrackTheme.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    Button("Omitir introducción", action: complete)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CaltrackTheme.muted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func feature(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 46, height: 46)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(CaltrackTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CaltrackTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(CaltrackTheme.line) }
    }
}
