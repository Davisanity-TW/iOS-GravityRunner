import SpriteKit

final class GameScene: SKScene {
    private enum PlayerState {
        case grounded
        case airborne
    }

    private let player = SKShapeNode(rectOf: CGSize(width: 42, height: 42), cornerRadius: 10)
    private var gravityDirection: CGFloat = 1
    private var lastUpdate: TimeInterval = 0
    private var verticalVelocity: CGFloat = 0
    private var playerState: PlayerState = .grounded

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.02, green: 0.05, blue: 0.09, alpha: 1)
        anchorPoint = CGPoint(x: 0, y: 0)
        physicsWorld.gravity = .zero
        buildLevel()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard playerState == .grounded else { return }

        playerState = .airborne
        gravityDirection *= -1
        verticalVelocity = -gravityDirection * 420
        player.fillColor = gravityDirection > 0 ? .systemMint : .systemYellow
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = min(currentTime - lastUpdate, 1.0 / 30.0)
        lastUpdate = currentTime
        verticalVelocity += gravityDirection * 1200 * delta
        player.position.y += verticalVelocity * delta

        let floor = CGFloat(92)
        let ceiling = size.height - 92
        if player.position.y < floor {
            land(on: floor)
        } else if player.position.y > ceiling {
            land(on: ceiling)
        }
    }

    private func land(on surfaceY: CGFloat) {
        player.position.y = surfaceY
        verticalVelocity = 0
        playerState = .grounded
    }

    private func buildLevel() {
        let floor = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 48))
        floor.position = CGPoint(x: size.width / 2, y: 48)
        floor.fillColor = .init(red: 0.05, green: 0.18, blue: 0.25, alpha: 1)
        floor.strokeColor = .systemTeal
        addChild(floor)

        let ceiling = floor.copy() as! SKShapeNode
        ceiling.position.y = size.height - 48
        addChild(ceiling)

        player.position = CGPoint(x: size.width * 0.25, y: 92)
        player.fillColor = .systemMint
        player.strokeColor = .white
        addChild(player)

        let title = SKLabelNode(text: "GRAVITY RUNNER · TAP TO FLIP")
        title.fontName = "Menlo-Bold"
        title.fontSize = 16
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height - 38)
        addChild(title)
    }
}
