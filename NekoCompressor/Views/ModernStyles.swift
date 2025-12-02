//
//  ModernStyles.swift
//  NekoCompressor
//
//  Created by Claude on 2025/12/1.
//

import SwiftUI

// MARK: - 現代化顏色主題

struct ModernColors {
    // 主要漸層
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.2, blue: 0.8),
            Color(red: 0.6, green: 0.3, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.8, blue: 0.6),
            Color(red: 0.1, green: 0.9, blue: 0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.6, blue: 0.2),
            Color(red: 1.0, green: 0.7, blue: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // 玻璃效果顏色
    static let glassFill = Color.white.opacity(0.05)
    static let glassStroke = Color.white.opacity(0.1)

    // 卡片背景
    static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.5)
}

// MARK: - 玻璃擬態卡片樣式

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ModernColors.glassFill)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(ModernColors.glassStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - 現代化按鈕樣式

struct ModernButtonStyle: ButtonStyle {
    var gradient: LinearGradient = ModernColors.primaryGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 漸層邊框

struct GradientBorder: ViewModifier {
    var gradient: LinearGradient
    var lineWidth: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: lineWidth)
            )
    }
}

extension View {
    func gradientBorder(
        _ gradient: LinearGradient,
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(GradientBorder(
            gradient: gradient,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - 脈動動畫

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseEffect() -> some View {
        modifier(PulseEffect())
    }
}

// MARK: - 閃光效果

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - 資訊卡片樣式

struct InfoCardStyle: ViewModifier {
    var icon: String
    var color: Color

    func body(content: Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
}

extension View {
    func infoCard(icon: String, color: Color) -> some View {
        modifier(InfoCardStyle(icon: icon, color: color))
    }
}
