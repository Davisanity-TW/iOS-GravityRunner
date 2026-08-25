import SpriteKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartScreenView()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct StartScreenView: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            ScreenImage(name: "StartScreen") {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: proxy.size.width * 0.27, height: proxy.size.height * 0.1)
                        .position(x: proxy.size.width * 0.54, y: proxy.size.height * 0.88)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScreenImage(name: "Settings") {
                GeometryReader { proxy in
                    NavigationLink {
                        EditorView()
                    } label: {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: proxy.size.width * 0.58, height: proxy.size.height * 0.2)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.54)
                    .accessibilityLabel("Map Editor")

                    Button {
                        dismiss()
                    } label: {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: proxy.size.width * 0.1, height: proxy.size.height * 0.12)
                    .position(x: proxy.size.width * 0.05, y: proxy.size.height * 0.07)
                    .accessibilityLabel("返回")
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ScreenImage<Overlay: View>: View {
    let name: String
    @ViewBuilder let overlay: () -> Overlay

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / 1669,
                proxy.size.height / 938
            )
            let imageSize = CGSize(
                width: 1669 * scale,
                height: 938 * scale
            )

            ZStack {
                Color.black

                ZStack {
                    Image(name)
                        .resizable()
                        .scaledToFit()

                    overlay()
                }
                .frame(width: imageSize.width, height: imageSize.height)
            }
        }
        .ignoresSafeArea()
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
    @State private var objects: [EditorObject] = []
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
                Text("\(Int(zoom * 100))%")
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EditorObjectKind.allCases) { kind in
                        PaletteItem(kind: kind)
                            .onDrag { NSItemProvider(object: kind.rawValue as NSString) }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.9))

            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.92)

                    EditorGrid(objects: objects)
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
                        .onDrop(of: [UTType.text], isTargeted: nil) { providers, location in
                            guard let provider = providers.first else { return false }
                            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                                let rawValue: String?
                                if let data = item as? Data {
                                    rawValue = String(data: data, encoding: .utf8)
                                } else if let string = item as? String {
                                    rawValue = string
                                } else if let string = item as? NSString {
                                    rawValue = string as String
                                } else {
                                    rawValue = nil
                                }

                                guard let rawValue, let kind = EditorObjectKind(rawValue: rawValue) else { return }

                                DispatchQueue.main.async {
                                    objects.append(EditorObject(kind: kind, position: location))
                                }
                            }
                            return true
                        }
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

private enum EditorObjectKind: String, CaseIterable, Identifiable {
    case platform = "平台"
    case hazard = "危險物"
    case spawn = "出生點"
    case finish = "終點"
    case checkpoint = "Checkpoint"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .platform: .mint
        case .hazard: .red
        case .spawn: .blue
        case .finish: .yellow
        case .checkpoint: .orange
        }
    }
}

private struct EditorObject: Identifiable {
    let id = UUID()
    let kind: EditorObjectKind
    let position: CGPoint
}

private struct PaletteItem: View {
    let kind: EditorObjectKind

    var body: some View {
        Label(kind.rawValue, systemImage: "square.fill")
            .font(.caption.bold())
            .foregroundStyle(kind.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: Capsule())
    }
}

private struct EditorGrid: View {
    let objects: [EditorObject]
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

            for object in objects {
                let frame = CGRect(x: object.position.x - 20, y: object.position.y - 20, width: 40, height: 40)
                context.fill(Path(roundedRect: frame, cornerRadius: 8), with: .color(object.kind.color))
            }
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
