import SwiftUI
import UIKit

struct InteractiveBackNavigation: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.enableInteractiveBack()
    }

    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.restoreGesture()
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        private weak var gesture: UIGestureRecognizer?
        private weak var originalDelegate: (any UIGestureRecognizerDelegate)?
        private var originallyEnabled = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            enableInteractiveBack()
        }

        func enableInteractiveBack() {
            guard let navigationController,
                let gesture = navigationController.interactivePopGestureRecognizer
            else { return }
            if self.gesture !== gesture {
                restoreGesture()
                self.gesture = gesture
                originalDelegate = gesture.delegate
                originallyEnabled = gesture.isEnabled
            }
            gesture.delegate = self
            gesture.isEnabled = true
        }

        func restoreGesture() {
            if let gesture, gesture.delegate === self {
                gesture.delegate = originalDelegate
                gesture.isEnabled = originallyEnabled
            }
            gesture = nil
            originalDelegate = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let navigationController else { return false }
            return navigationController.viewControllers.count > 1
                && navigationController.transitionCoordinator == nil
                && navigationController.presentedViewController == nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: other) ?? false
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer
        ) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: other) ?? false
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: other) ?? false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) ?? true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
            originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) ?? true
        }
    }
}
