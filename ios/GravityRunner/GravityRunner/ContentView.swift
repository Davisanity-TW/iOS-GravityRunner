import SpriteKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(red: 0.02, green: 0.12, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text("GRAVITY RUNNER")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("翻轉重力，跑出你的路")
                        .foregroundStyle(.mint)

                    VStack(spacing: 14) {
                        NavigationLink("開始遊戲") {
                            GameView()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        NavigationLink("地圖編輯器") {
                            EditorView()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .frame(maxWidth: 320)

                    Spacer()

                    Text("Prototype · iOS")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(32)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct GameView: View {
    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: GameScene(size: proxy.size))
                .ignoresSafeArea()
                .background(.black)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct EditorView: View {
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchZoom: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("我的關卡")
                    .font(.headline)
                Spacer()
                Text("(Int(zoom * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("重設") {
                    zoom = 1
                    offset = .zero
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.92)

                    EditorGrid()
                        .scaleEffect(zoom * pinchZoom)
                        .offset(
                            x: offset.width + dragOffset.width,
                            y: offset.height + dragOffset.height
                        )
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    offset.width += value.translation.width
                                    offset.height += value.translation.height
                                }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .updating($pinchZoom) { value, state, _ in
                                    state = value
                                }
                                .onEnded { value in
                                    zoom = min(max(zoom * value, 0.5), 2.5)
                                }
                        )
                }
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text("拖曳平移 · 雙指縮放")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(10)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("安全區")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(8)
                        .background(.black.opacity(0.5), in: Capsule())
                        .padding()
                }
            }
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct EditorGrid: View {
    private let size = CGSize(width: 1100, height: 650)
    private let cell: CGFloat = 40

    var body: some View {
        Canvas { context, _ in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(Color(red: 0.04, green: 0.08, blue: 0.12)))

            var grid = Path()
            stride(from: CGFloat.zero, through: size.width, by: cell).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat.zero, through: size.height, by: cell).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(grid, with: .color(.white.opacity(0.12)), lineWidth: 1)

            context.fill(
                Path(CGRect(x: 80, y: 520, width: 260, height: 28)),
                with: .color(.mint)
            )
            context.fill(
                Path(CGRect(x: 500, y: 360, width: 220, height: 28)),
                with: .color(.orange)
            )
            context.fill(
                Path(CGRect(x: 840, y: 140, width: 180, height: 28)),
                with: .color(.pink)
            )
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            Text("START")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(6)
                .background(.blue, in: RoundedRectangle(cornerRadius: 6))
                .offset(x: 80, y: 480)
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.mint, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.black)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(configuration.isPressed ? 0.25 : 0.12), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
}
