import SwiftUI
import UIKit

final class ThemeTransition {
    private static let fadeDuration: TimeInterval = 0.3
    private static let timeout = Duration.seconds(1.5)

    private var cover: UIView?
    private var isRevealing = false
    private var timeoutTask: Task<Void, Never>?

    func begin(in content: UIView?) {
        if isRevealing {
            end()
        }
        guard cover == nil, let content,
            let snapshot = content.snapshotView(afterScreenUpdates: false)
        else {
            return
        }
        snapshot.frame = content.bounds
        snapshot.isUserInteractionEnabled = false
        content.addSubview(snapshot)
        cover = snapshot
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: Self.timeout)
            if !Task.isCancelled {
                self?.reveal()
            }
        }
    }

    func reveal() {
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let cover, !isRevealing else {
            return
        }
        isRevealing = true
        UIView.animate(withDuration: Self.fadeDuration) {
            cover.alpha = 0
        } completion: { [weak self] _ in
            cover.removeFromSuperview()
            if self?.cover === cover {
                self?.cover = nil
                self?.isRevealing = false
            }
        }
    }

    func end() {
        timeoutTask?.cancel()
        timeoutTask = nil
        cover?.layer.removeAllAnimations()
        cover?.removeFromSuperview()
        cover = nil
        isRevealing = false
    }
}

final class WindowReference {
    weak var window: UIWindow?
}

struct WindowAnchor: UIViewRepresentable {
    let reference: WindowReference

    func makeUIView(context: Context) -> AnchorView {
        AnchorView(reference: reference)
    }

    func updateUIView(_ view: AnchorView, context: Context) {}

    final class AnchorView: UIView {
        private let reference: WindowReference

        init(reference: WindowReference) {
            self.reference = reference
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window {
                reference.window = window
            }
        }
    }
}
