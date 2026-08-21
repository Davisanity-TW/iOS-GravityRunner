import SpriteKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: GameScene(size: proxy.size))
                .ignoresSafeArea()
                .background(.black)
        }
    }
}

#Preview {
    ContentView()
}
