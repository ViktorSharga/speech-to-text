import HotKey
import Carbon

class HotkeyManager {
    private var hotKey: HotKey?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        registerHotkey()
    }

    private func registerHotkey() {
        hotKey = HotKey(key: .f5, modifiers: [])
        hotKey?.keyDownHandler = { [weak self] in
            self?.action()
        }
    }

    deinit {
        hotKey = nil
    }
}
