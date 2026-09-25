"""Run with python3 ios/GravityRunforge/checks/check_map_height.py (requires Swift)."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / 'GravityRunforge/ContentView.swift').read_text()
models = source[source.index('private enum MapSizeOption:'):source.index('private enum LocalMapStore {')]
checks = r'''
for height: CGFloat in [240, 300, 402, 440, 650, 834, 900, 1024] {
    for (option, length) in zip(MapSizeOption.allCases, [2000, 8000, 10000, 12000]) {
        assert(option.canvasSize(height: height) == CGSize(width: CGFloat(length), height: height))
        assert(!option.label.contains("650") && !option.label.contains("×"))
    }
    let original = [20.0, 325.0, 630.0].map {
        EditorObject(kind: .platform, position: CGPoint(x: 120, y: $0))
    }
    let resized = original.fittingMapHeight(from: 650, to: height)
    assert(resized.count == original.count)
    assert(resized[0].position.y == 20)
    assert(resized[1].position.y == height / 2)
    assert(resized[2].position.y == height - 20)
    for (old, new) in zip(original, resized) {
        assert(old.id == new.id && old.position.x == new.position.x)
        assert(new.position.y >= new.size / 2 && new.position.y <= height - new.size / 2)
    }
    let restored = resized.fittingMapHeight(from: height, to: 650)
    assert(abs(restored[1].position.y - 325) < 0.001)
    let map = SavedMap(name: "test", objects: resized, mapSize: .xs, canvasHeight: height)
    let data = try JSONEncoder().encode(map)
    let loaded = try JSONDecoder().decode(SavedMap.self, from: data)
    assert(loaded.canvasHeight == height && loaded.mapSize == .xs && loaded.objects.count == 3)
    var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    legacy.removeValue(forKey: "canvasHeight")
    let legacyMap = try JSONDecoder().decode(SavedMap.self, from: JSONSerialization.data(withJSONObject: legacy))
    assert(legacyMap.canvasHeight == 650)
}
private let large = [EditorObject(kind: .platform, position: CGPoint(x: 100, y: 550), size: 200)]
private let tiny = large.fittingMapHeight(from: 650, to: 100)[0]
assert(tiny.size == 100 && tiny.position.y == 50)
print("PASS: adaptive map sizes, edge placement, resize, save/load, legacy migration")
'''
with tempfile.TemporaryDirectory(prefix='gravity-map-check-') as directory:
    path = Path(directory) / 'main.swift'
    path.write_text('import Foundation\nimport CoreGraphics\nprivate enum EditorObjectKind: String, Codable { case platform }\n' + models + checks)
    subprocess.run(['swift', '-module-cache-path', '/tmp/gravity-map-swift-cache', str(path)], check=True)
