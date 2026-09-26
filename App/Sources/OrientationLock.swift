import SwiftUI
import UIKit

@Observable
final class OrientationLock {
    private(set) var mask = UIInterfaceOrientationMask.all

    func lock(in window: UIWindow?) {
        guard let window, let orientation = window.windowScene?.effectiveGeometry.interfaceOrientation else {
            return
        }
        mask = orientation.mask
        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    func unlock(in window: UIWindow?) {
        mask = .all
        window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    let orientationLock = OrientationLock()

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)
        -> UIInterfaceOrientationMask
    {
        orientationLock.mask
    }
}

extension UIInterfaceOrientation {
    fileprivate var mask: UIInterfaceOrientationMask {
        switch self {
        case .portraitUpsideDown: .portraitUpsideDown
        case .landscapeLeft: .landscapeLeft
        case .landscapeRight: .landscapeRight
        default: .portrait
        }
    }
}
