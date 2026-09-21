import SpriteKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Foundation

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
        ScreenImage(name: "StartScreen") {
            GeometryReader { proxy in
                let mainButtonSize = CGSize(
                    width: proxy.size.width * 0.265,
                    height: proxy.size.height * 0.105
                )

                NavigationLink {
                    GameView()
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: mainButtonSize.width, height: mainButtonSize.height)
                }
                .buttonStyle(PressFeedbackStyle())
                .position(x: proxy.size.width * 0.515, y: proxy.size.height * 0.54)
                .accessibilityLabel("Single Run")

                Button(action: {}) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: mainButtonSize.width, height: mainButtonSize.height)
                }
                .buttonStyle(PressFeedbackStyle())
                .position(x: proxy.size.width * 0.515, y: proxy.size.height * 0.66)
                .accessibilityLabel("Multi Run")

                Button(action: {}) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: mainButtonSize.width, height: mainButtonSize.height)
                }
                .buttonStyle(PressFeedbackStyle())
                .position(x: proxy.size.width * 0.515, y: proxy.size.height * 0.78)
                .accessibilityLabel("Practice")

                NavigationLink {
                    SettingsView()
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: mainButtonSize.width, height: mainButtonSize.height)
                }
                .buttonStyle(PressFeedbackStyle())
                .position(x: proxy.size.width * 0.515, y: proxy.size.height * 0.90)
                .accessibilityLabel("Settings")
            }
        }
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
                    .buttonStyle(PressFeedbackStyle())
                    .frame(width: proxy.size.width * 0.58, height: proxy.size.height * 0.2)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.54)
                    .accessibilityLabel("Map Editor")

                    Button {
                        dismiss()
                    } label: {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressFeedbackStyle(showGlow: false))
                    .frame(width: proxy.size.width * 0.1, height: proxy.size.height * 0.12)
                    .position(x: proxy.size.width * 0.05, y: proxy.size.height * 0.07)
                    .accessibilityLabel("返回")
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("返回", systemImage: "chevron.left")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.65), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.cyan.opacity(0.75), lineWidth: 1)
                }
        }
        .buttonStyle(PressFeedbackStyle(showGlow: false))
        .accessibilityLabel("返回")
    }
}

private struct PressFeedbackStyle: ButtonStyle {
    var showGlow = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                if configuration.isPressed && showGlow {
                    Image("ButtonPressedGlow")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.9)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .shadow(color: .cyan.opacity(configuration.isPressed ? 0.8 : 0), radius: 14)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
            .onChange(of: configuration.isPressed) { _, isPressed in
                guard isPressed else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
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

                ZStack(alignment: .topLeading) {
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { proxy in
                SpriteView(scene: GameScene(size: proxy.size))
                    .ignoresSafeArea()
                    .background(.black)
            }

            BackButton {
                dismiss()
            }
            .padding(.top, 12)
            .padding(.leading, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var objects: [EditorObject] = []
    @State private var undoStack: [[EditorObject]] = []
    @State private var savedMaps = LocalMapStore.load()
    @State private var currentMapID: UUID?
    @State private var mapName = "未命名地圖"
    @State private var selectedObjectID: UUID?
    @State private var paintKind: EditorObjectKind?
    @State private var isEraseMode = false
    @State private var showMapLibrary = false
    @State private var showSavePrompt = false
    @State private var showLimitAlert = false
    @State private var draftMapName = ""
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var mapSizeOption: MapSizeOption = .small
    @GestureState private var pinchZoom: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BackButton {
                    dismiss()
                }

                Text(mapName)
                    .font(.headline)
                Spacer()
                Text("\(Int(zoom * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    isEraseMode.toggle()
                    paintKind = nil
                    selectedObjectID = nil
                } label: {
                    Label("橡皮擦", systemImage: isEraseMode ? "eraser.fill" : "eraser")
                        .font(.caption.bold())
                        .foregroundStyle(isEraseMode ? .black : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(isEraseMode ? Color.yellow : Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressFeedbackStyle(showGlow: false))
                .accessibilityLabel(isEraseMode ? "關閉橡皮擦" : "開啟橡皮擦")
                Button {
                    guard let previous = undoStack.popLast() else { return }
                    objects = previous
                    selectedObjectID = nil
                } label: {
                    Label("復原", systemImage: "arrow.uturn.backward")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressFeedbackStyle(showGlow: false))
                .disabled(undoStack.isEmpty)
                Button {
                    saveMap()
                } label: {
                    Label("儲存", systemImage: "square.and.arrow.down")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressFeedbackStyle(showGlow: false))
                Button {
                    showMapLibrary = true
                } label: {
                    Label("地圖", systemImage: "folder")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressFeedbackStyle(showGlow: false))
                Menu {
                    ForEach(MapSizeOption.allCases) { option in
                        Button {
                            mapSizeOption = option
                            offset = .zero
                            zoom = 1
                        } label: {
                            Label(option.label, systemImage: mapSizeOption == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    Label("尺寸 (mapSizeOption.rawValue)", systemImage: "rectangle.resize")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(PressFeedbackStyle(showGlow: false))
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
                            .onTapGesture {
                                paintKind = kind
                                isEraseMode = false
                                selectedObjectID = nil
                            }
                            .overlay {
                                if paintKind == kind {
                                    Capsule()
                                        .stroke(.yellow, lineWidth: 2)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.9))

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    Color.black.opacity(0.92)

                    EditorGrid(
                        objects: $objects,
                        selectedObjectID: $selectedObjectID,
                        zoom: zoom * pinchZoom,
                        mapSize: mapSizeOption.canvasSize,
                        contentOffset: offset,
                        paintKind: paintKind,
                        isErasing: isEraseMode,
                        onEditStart: { undoStack.append(objects) },
                        onPaintStart: { undoStack.append(objects) },
                        onPaint: { kind, points in
                            for point in points.map({ $0.clampedToMap(size: mapSizeOption.canvasSize, objectSize: 40) })
                            where !objects.contains(where: { $0.kind == kind && $0.position == point }) {
                                objects.append(EditorObject(kind: kind, position: point))
                            }
                        },
                        onErase: { points in
                            objects.removeAll { points.contains($0.position) }
                            selectedObjectID = nil
                        },
                        onBlankTap: {
                            paintKind = nil
                            isEraseMode = false
                            selectedObjectID = nil
                        },
                        onPan: { delta in
                            let scale = zoom * pinchZoom
                            offset = clampedOffset(
                                CGSize(
                                    width: offset.width + delta.width,
                                    height: offset.height + delta.height
                                ),
                                viewport: proxy.size,
                                scale: scale
                            )
                        },
                        onDelete: { id in
                            guard objects.contains(where: { $0.id == id }) else { return }
                            undoStack.append(objects)
                            objects.removeAll { $0.id == id }
                            selectedObjectID = nil
                        }
                    )
                        .scaleEffect(zoom * pinchZoom, anchor: .topLeading)
                        .offset(
                            x: offset.width,
                            y: offset.height
                        )
                        .allowsHitTesting(paintKind == nil && !isEraseMode)
                        .simultaneousGesture(
                            MagnificationGesture()
                                .updating($pinchZoom) { value, state, _ in
                                    guard paintKind == nil && !isEraseMode else { return }
                                    state = value
                                }
                                .onEnded { value in
                                    guard paintKind == nil && !isEraseMode else { return }
                                    zoom = min(max(zoom * value, 0.5), 2.5)
                                    offset = clampedOffset(
                                        offset,
                                        viewport: proxy.size,
                                        scale: zoom
                                    )
                                }
                        )

                    if paintKind != nil || isEraseMode {
                        EditorPaintOverlay(
                            zoom: zoom * pinchZoom,
                            contentOffset: offset,
                            paintKind: paintKind,
                            isErasing: isEraseMode,
                            onPaintStart: { undoStack.append(objects) },
                            onPaint: { kind, points in
                                for point in points.map({ $0.clampedToMap(size: mapSizeOption.canvasSize, objectSize: 40) })
                                where !objects.contains(where: { $0.kind == kind && $0.position == point }) {
                                    objects.append(EditorObject(kind: kind, position: point))
                                }
                            },
                            onErase: { points in
                                objects.removeAll { points.contains($0.position) }
                                selectedObjectID = nil
                            },
                            onBlankTap: {
                                paintKind = nil
                                isEraseMode = false
                                selectedObjectID = nil
                            }
                        )
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
        .sheet(isPresented: $showMapLibrary) {
            MapLibraryView(
                maps: $savedMaps,
                currentMapID: currentMapID,
                onLoad: loadMap,
                onCreateNew: createNewMap,
                onDelete: deleteMap,
                onRename: renameMap
            )
        }
        .alert("儲存地圖", isPresented: $showSavePrompt) {
            TextField("地圖名稱", text: $draftMapName)
            Button("儲存", action: saveNewMap)
            Button("取消", role: .cancel) { }
        } message: {
            Text("最多可在本機保存 10 張地圖")
        }
        .alert("地圖數量已達上限", isPresented: $showLimitAlert) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("請先刪除一張地圖，再建立新的地圖。")
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func clampedOffset(_ proposed: CGSize, viewport: CGSize, scale: CGFloat) -> CGSize {
        let scaledMapSize = CGSize(
            width: mapSizeOption.canvasSize.width * scale,
            height: mapSizeOption.canvasSize.height * scale
        )
        let minX = min(0, viewport.width - scaledMapSize.width)
        let minY = min(0, viewport.height - scaledMapSize.height)
        return CGSize(
            width: min(max(proposed.width, minX), 0),
            height: min(max(proposed.height, minY), 0)
        )
    }

    private func saveMap() {
        if let currentMapID,
           let index = savedMaps.firstIndex(where: { $0.id == currentMapID }) {
            savedMaps[index].name = mapName
            savedMaps[index].objects = objects
            savedMaps[index].mapSize = mapSizeOption
            savedMaps[index].updatedAt = Date()
            LocalMapStore.save(savedMaps)
        } else if savedMaps.count < LocalMapStore.maxMapCount {
            draftMapName = mapName
            showSavePrompt = true
        } else {
            showLimitAlert = true
        }
    }

    private func saveNewMap() {
        let name = draftMapName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, savedMaps.count < LocalMapStore.maxMapCount else { return }
        let map = SavedMap(name: name, objects: objects, mapSize: mapSizeOption)
        savedMaps.append(map)
        currentMapID = map.id
        mapName = map.name
        mapSizeOption = map.mapSize
        LocalMapStore.save(savedMaps)
    }

    private func loadMap(_ map: SavedMap) {
        objects = map.objects
        currentMapID = map.id
        mapName = map.name
        mapSizeOption = map.mapSize
        paintKind = nil
        isEraseMode = false
        selectedObjectID = nil
        undoStack.removeAll()
    }

    private func createNewMap() {
        objects = []
        currentMapID = nil
        mapName = "未命名地圖"
        mapSizeOption = .small
        paintKind = nil
        isEraseMode = false
        selectedObjectID = nil
        undoStack.removeAll()
    }

    private func deleteMap(_ map: SavedMap) {
        savedMaps.removeAll { $0.id == map.id }
        if currentMapID == map.id {
            objects = []
            currentMapID = nil
            mapName = "未命名地圖"
            mapSizeOption = .small
            paintKind = nil
            isEraseMode = false
            selectedObjectID = nil
            undoStack.removeAll()
        }
        LocalMapStore.save(savedMaps)
    }

    private func renameMap(_ map: SavedMap, to name: String) {
        guard let index = savedMaps.firstIndex(where: { $0.id == map.id }) else { return }
        savedMaps[index].name = name
        savedMaps[index].updatedAt = Date()
        if currentMapID == map.id { mapName = name }
        LocalMapStore.save(savedMaps)
    }
}

private enum EditorObjectKind: String, CaseIterable, Identifiable, Codable {
    case platform = "平台"
    case hazard = "危險物"
    case speed = "加速方塊"
    case spawn = "出生點"
    case finish = "終點"
    case checkpoint = "Checkpoint"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .platform: .mint
        case .hazard: .red
        case .speed: .green
        case .spawn: .blue
        case .finish: .yellow
        case .checkpoint: .orange
        }
    }

    var assetName: String {
        switch self {
        case .platform, .spawn, .finish, .checkpoint: "GroundBlockV2"
        case .hazard: "VerticalBlock"
        case .speed: "SpeedBlockV2"
        }
    }
}

private enum MapSizeOption: String, CaseIterable, Identifiable, Codable {
    case xs = "XS"
    case small = "S"
    case medium = "M"
    case large = "L"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .xs: "XS（2000 × 650）"
        case .small: "S（8000 × 650）"
        case .medium: "M（10000 × 650）"
        case .large: "L（12000 × 650）"
        }
    }

    var canvasSize: CGSize {
        switch self {
        case .xs: CGSize(width: 2000, height: 650)
        case .small: CGSize(width: 8000, height: 650)
        case .medium: CGSize(width: 10000, height: 650)
        case .large: CGSize(width: 12000, height: 650)
        }
    }
}

private struct EditorObject: Identifiable, Codable {
    let id = UUID()
    let kind: EditorObjectKind
    var position: CGPoint
    var size: CGFloat = 40
}

private struct SavedMap: Identifiable, Codable {
    let id: UUID
    var name: String
    var objects: [EditorObject]
    var mapSize: MapSizeOption
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, objects: [EditorObject], mapSize: MapSizeOption = .small, updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.objects = objects
        self.mapSize = mapSize
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey { case id, name, objects, mapSize, updatedAt }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        objects = try container.decode([EditorObject].self, forKey: .objects)
        mapSize = try container.decodeIfPresent(MapSizeOption.self, forKey: .mapSize) ?? .small
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

private enum LocalMapStore {
    static let maxMapCount = 10
    private static let key = "gravity-runforge.saved-maps.v1"

    static func load() -> [SavedMap] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let maps = try? JSONDecoder().decode([SavedMap].self, from: data) else { return [] }
        return Array(maps.sorted { $0.updatedAt > $1.updatedAt }.prefix(maxMapCount))
    }

    static func save(_ maps: [SavedMap]) {
        guard let data = try? JSONEncoder().encode(maps) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct MapLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var maps: [SavedMap]
    let currentMapID: UUID?
    let onLoad: (SavedMap) -> Void
    let onCreateNew: () -> Void
    let onDelete: (SavedMap) -> Void
    let onRename: (SavedMap, String) -> Void
    @State private var renameTarget: SavedMap?
    @State private var renameDraft = ""
    @State private var showRenamePrompt = false

    var body: some View {
        NavigationStack {
            Group {
                if maps.isEmpty {
                    ContentUnavailableView("尚未儲存地圖", systemImage: "map", description: Text("在編輯器中按下儲存即可建立地圖。"))
                } else {
                    List {
                        ForEach(maps.sorted { $0.updatedAt > $1.updatedAt }) { map in
                            HStack(spacing: 12) {
                                Button {
                                    onLoad(map)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(map.name)
                                            .foregroundStyle(.primary)
                                        Text("更新於 \(map.updatedAt.formatted(date: .abbreviated, time: .shortened)) · \(map.objects.count) 個方塊")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                if currentMapID == map.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }

                                Menu {
                                    Button("重新命名", systemImage: "pencil") {
                                        renameTarget = map
                                        renameDraft = map.name
                                        showRenamePrompt = true
                                    }
                                    Button("刪除", systemImage: "trash", role: .destructive) { onDelete(map) }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("我的地圖 (\(maps.count)/10)")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("新增", systemImage: "plus") {
                        onCreateNew()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("重新命名地圖", isPresented: $showRenamePrompt) {
                TextField("地圖名稱", text: $renameDraft)
                Button("儲存") {
                    let name = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty, let renameTarget else { return }
                    onRename(renameTarget, name)
                }
                Button("取消", role: .cancel) { }
            }
        }
    }
}

private struct PaletteItem: View {
    let kind: EditorObjectKind

    var body: some View {
        HStack(spacing: 6) {
            Image(kind.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text(kind.rawValue)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: Capsule())
    }
}

private struct EditorPaintOverlay: View {
    let zoom: CGFloat
    let contentOffset: CGSize
    let paintKind: EditorObjectKind?
    let isErasing: Bool
    let onPaintStart: () -> Void
    let onPaint: (EditorObjectKind, [CGPoint]) -> Void
    let onErase: ([CGPoint]) -> Void
    let onBlankTap: () -> Void
    private let cell: CGFloat = 40
    @State private var lastPoint: CGPoint?
    @State private var isPainting = false

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if !isPainting {
                            isPainting = true
                            onPaintStart()
                        }

                        let points = paintPoints(from: lastPoint ?? value.location, to: value.location)
                        if isErasing {
                            onErase(points)
                        } else if let paintKind {
                            onPaint(paintKind, points)
                        }
                        lastPoint = value.location
                    }
                    .onEnded { _ in
                        lastPoint = nil
                        isPainting = false
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        onBlankTap()
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func paintPoints(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = max(abs(dx), abs(dy))
        let steps = max(Int(distance / (cell / 2)), 1)
        var seen = Set<String>()

        return (0...steps).compactMap { index in
            let progress = CGFloat(index) / CGFloat(steps)
            let touchPoint = CGPoint(
                x: start.x + dx * progress,
                y: start.y + dy * progress
            )
            let point = CGPoint(
                x: (touchPoint.x - contentOffset.width) / max(zoom, 0.01),
                y: (touchPoint.y - contentOffset.height) / max(zoom, 0.01)
            ).snappedToGrid
            let key = "\(point.x):\(point.y)"
            guard seen.insert(key).inserted else { return nil }
            return point
        }
    }
}

private struct EditorGrid: View {
    @Binding var objects: [EditorObject]
    @Binding var selectedObjectID: UUID?
    let zoom: CGFloat
    let mapSize: CGSize
    let contentOffset: CGSize
    let paintKind: EditorObjectKind?
    let isErasing: Bool
    let onEditStart: () -> Void
    let onPaintStart: () -> Void
    let onPaint: (EditorObjectKind, [CGPoint]) -> Void
    let onErase: ([CGPoint]) -> Void
    let onBlankTap: () -> Void
    let onPan: (CGSize) -> Void
    let onDelete: (UUID) -> Void
    private let cell: CGFloat = 40
    @State private var lastPaintPoint: CGPoint?
    @State private var isPainting = false
    @State private var lastPanTranslation: CGSize = .zero

    var body: some View {
        Canvas { context, _ in
            let rect = CGRect(origin: .zero, size: mapSize)
            context.fill(Path(rect), with: .color(Color(red: 0.04, green: 0.08, blue: 0.12)))

            var grid = Path()
            stride(from: CGFloat.zero, through: mapSize.width, by: cell).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: mapSize.height))
            }
            stride(from: CGFloat.zero, through: mapSize.height, by: cell).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: mapSize.width, y: y))
            }
            context.stroke(grid, with: .color(.white.opacity(0.12)), lineWidth: 1)

            for x in stride(from: CGFloat.zero, through: mapSize.width, by: 200) {
                var axis = Path()
                axis.move(to: CGPoint(x: x, y: 0))
                axis.addLine(to: CGPoint(x: x, y: mapSize.height))
                context.stroke(axis, with: .color(.cyan.opacity(0.5)), lineWidth: 2.5)
                context.draw(
                    Text("\(Int(x))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8)),
                    at: CGPoint(x: min(x + 18, mapSize.width - 18), y: 12)
                )
            }

            for y in stride(from: CGFloat.zero, through: mapSize.height, by: 200) {
                var axis = Path()
                axis.move(to: CGPoint(x: 0, y: y))
                axis.addLine(to: CGPoint(x: mapSize.width, y: y))
                context.stroke(axis, with: .color(.cyan.opacity(0.5)), lineWidth: 2.5)
                context.draw(
                    Text("\(Int(y))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8)),
                    at: CGPoint(x: 18, y: min(y + 12, mapSize.height - 12))
                )
            }

        }
        .frame(width: mapSize.width, height: mapSize.height)
        .contentShape(Rectangle())
        .onTapGesture {
            onBlankTap()
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard paintKind != nil || isErasing else { return }
                    if !isPainting {
                        isPainting = true
                        onPaintStart()
                    }
                    let points = paintPoints(from: lastPaintPoint ?? value.location, to: value.location)
                    if isErasing {
                        onErase(points)
                    } else if let paintKind {
                        onPaint(paintKind, points)
                    }
                    lastPaintPoint = value.location
                }
                .onEnded { _ in
                    lastPaintPoint = nil
                    isPainting = false
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard paintKind == nil && !isErasing else { return }
                    let delta = CGSize(
                        width: value.translation.width - lastPanTranslation.width,
                        height: value.translation.height - lastPanTranslation.height
                    )
                    onPan(delta)
                    lastPanTranslation = value.translation
                }
                .onEnded { _ in
                    lastPanTranslation = .zero
                }
        )
        .overlay(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                ForEach($objects) { $object in
                    EditorObjectHandle(
                        object: $object,
                        zoom: zoom,
                        isErasing: isErasing,
                        isSelected: selectedObjectID == object.id,
                        mapSize: mapSize,
                        onSelect: { selectedObjectID = object.id },
                        onEditStart: onEditStart,
                        onDelete: onDelete
                    )
                    .offset(
                        x: object.position.x - object.size / 2,
                        y: object.position.y - object.size / 2
                    )
                }
            }
            .frame(width: mapSize.width, height: mapSize.height, alignment: .topLeading)
        }
    }

    private func paintPoints(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = max(abs(dx), abs(dy))
        let steps = max(Int(distance / (cell / 2)), 1)
        var seen = Set<String>()
        return (0...steps).compactMap { index in
            let progress = CGFloat(index) / CGFloat(steps)
            let touchPoint = CGPoint(
                x: start.x + dx * progress,
                y: start.y + dy * progress
            )
            let point = CGPoint(
                x: (touchPoint.x - contentOffset.width) / max(zoom, 0.01),
                y: (touchPoint.y - contentOffset.height) / max(zoom, 0.01)
            ).snappedToGrid
            let key = "\(point.x):\(point.y)"
            guard seen.insert(key).inserted else { return nil }
            return point
        }
    }
}

private struct EditorObjectHandle: View {
    @Binding var object: EditorObject
    let zoom: CGFloat
    let isErasing: Bool
    let isSelected: Bool
    let mapSize: CGSize
    let onSelect: () -> Void
    let onEditStart: () -> Void
    let onDelete: (UUID) -> Void
    @State private var dragStart: CGPoint?
    @State private var sizeStart: CGFloat?

    var body: some View {
        ZStack {
            Image(object.kind.assetName)
                .resizable()
                .scaledToFit()

            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.7), in: Circle())
                            .offset(x: 9, y: 9)
                    }
            }
        }
        .frame(width: object.size, height: object.size)
        .contentShape(Rectangle())
        .onTapGesture {
            if isErasing {
                onDelete(object.id)
            } else {
                onSelect()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !isErasing else { return }
                    if dragStart == nil {
                        dragStart = object.position
                        onEditStart()
                        onSelect()
                    }
                    guard let dragStart else { return }
                    object.position = CGPoint(
                        x: dragStart.x + value.translation.width / max(zoom, 0.01),
                        y: dragStart.y + value.translation.height / max(zoom, 0.01)
                    ).snappedToGrid.clampedToMap(size: mapSize, objectSize: object.size)
                }
                .onEnded { _ in
                    dragStart = nil
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    guard !isErasing else { return }
                    if sizeStart == nil {
                        sizeStart = object.size
                        onEditStart()
                        onSelect()
                    }
                    guard let sizeStart else { return }
                    object.size = min(max((sizeStart * value).snappedToGrid, 40), 200)
                }
                .onEnded { _ in
                    sizeStart = nil
                }
        )
    }
}

private extension CGPoint {
    var snappedToGrid: CGPoint {
        CGPoint(x: (x / 40).rounded() * 40, y: (y / 40).rounded() * 40)
    }

    func clampedToMap(size: CGSize, objectSize: CGFloat) -> CGPoint {
        let inset = objectSize / 2
        return CGPoint(
            x: min(max(x, inset), size.width - inset),
            y: min(max(y, inset), size.height - inset)
        )
    }
}

private extension CGFloat {
    var snappedToGrid: CGFloat {
        (self / 40).rounded() * 40
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
