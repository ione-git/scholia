import UIKit

final class PageCurl: NSObject {
    let controller: UIPageViewController
    let pan: UIPanGestureRecognizer?
    var allowsCurl: ((UIPanGestureRecognizer) -> Bool)?
    var onBegin: (() -> Void)?
    var onEnd: ((_ forward: Bool, _ completed: Bool) -> Void)?
    private(set) var isCurling = false
    private var current: Leaf?
    private var before: Leaf?
    private var after: Leaf?
    private var turnsForward = false
    private var hasBegun = false
    private var panDelegate: CurlPanDelegate?
    private var staged: Staging?
    private let isRightToLeft: Bool

    init(isRightToLeft: Bool) {
        self.isRightToLeft = isRightToLeft
        let spine: UIPageViewController.SpineLocation = isRightToLeft ? .max : .min
        controller = UIPageViewController(
            transitionStyle: .pageCurl, navigationOrientation: .horizontal,
            options: [.spineLocation: spine.rawValue])
        controller.isDoubleSided = true
        pan = controller.gestureRecognizers.lazy.compactMap { $0 as? UIPanGestureRecognizer }.first
        super.init()
        controller.dataSource = self
        controller.delegate = self
        for recognizer in controller.gestureRecognizers where recognizer !== pan {
            recognizer.isEnabled = false
        }
        if let pan, let original = pan.delegate {
            let panDelegate = CurlPanDelegate(curl: self, original: original)
            pan.delegate = panDelegate
            self.panDelegate = panDelegate
        }
        pan?.addTarget(self, action: #selector(panned))
        controller.view.isHidden = true
        controller.view.accessibilityElementsHidden = true
    }

    func stage(_ neighbours: NeighbourPages, color: UIColor) {
        guard let page = neighbours.page, let shot = neighbours.shots[page] else {
            return
        }
        let staging = Staging(page: page, previous: neighbours.previous, next: neighbours.next, color: color)
        guard staging != staged else {
            return
        }
        let current = Leaf(shot: shot, color: color)
        self.current = current
        let previous = neighbours.shot(neighbours.previous).map { Leaf(shot: $0, color: color) }
        let next = neighbours.shot(neighbours.next).map { Leaf(shot: $0, color: color) }
        before = isRightToLeft ? next : previous
        after = isRightToLeft ? previous : next
        controller.setViewControllers([current.front], direction: .forward, animated: false)
        staged = staging
    }

    func isStaged(_ neighbours: NeighbourPages, color: UIColor) -> Bool {
        guard let page = neighbours.page else {
            return false
        }
        return staged == Staging(page: page, previous: neighbours.previous, next: neighbours.next, color: color)
    }

    func unstage() {
        staged = nil
    }

    func reveal() {
        hasBegun = false
        controller.view.isHidden = false
        Task { [weak self] in
            self?.restUnlessBegun()
        }
    }

    func rest() {
        controller.view.isHidden = true
    }

    fileprivate func restUnlessBegun() {
        if !hasBegun, pan?.state != .began, pan?.state != .changed {
            rest()
        }
    }

    @objc private func panned(_ pan: UIPanGestureRecognizer) {
        if pan.state == .ended || pan.state == .cancelled {
            restUnlessBegun()
        }
    }
}

extension PageCurl: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if viewController === current?.front {
            return before?.back
        }
        if viewController === before?.back {
            return before?.front
        }
        return nil
    }

    func pageViewController(
        _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if viewController === current?.front {
            return current?.back
        }
        if viewController === current?.back {
            return after?.front
        }
        return nil
    }
}

extension PageCurl: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]
    ) {
        isCurling = true
        hasBegun = true
        turnsForward = pendingViewControllers.contains { $0 === after?.front } != isRightToLeft
        controller.view.isHidden = false
        onBegin?()
    }

    func pageViewController(
        _ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController], transitionCompleted completed: Bool
    ) {
        isCurling = false
        if completed {
            staged = nil
        }
        onEnd?(turnsForward, completed)
    }
}

private final class CurlPanDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var curl: PageCurl?
    private weak var original: UIGestureRecognizerDelegate?

    init(curl: PageCurl, original: UIGestureRecognizerDelegate) {
        self.curl = curl
        self.original = original
    }

    nonisolated override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || MainActor.assumeIsolated { original?.responds(to: selector) == true }
    }

    nonisolated override func forwardingTarget(for selector: Selector!) -> Any? {
        MainActor.assumeIsolated { original }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let curl, let pan = gestureRecognizer as? UIPanGestureRecognizer, curl.allowsCurl?(pan) == true else {
            return false
        }
        let begins = original?.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
        if !begins {
            curl.restUnlessBegun()
        }
        return begins
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard
            otherGestureRecognizer is UIPanGestureRecognizer,
            let view = gestureRecognizer.view,
            let otherView = otherGestureRecognizer.view,
            otherView !== view, otherView.isDescendant(of: view)
        else {
            return false
        }
        return true
    }
}

private struct Staging: Equatable {
    let page: ChapterPage
    let previous: Neighbour?
    let next: Neighbour?
    let color: UIColor
}

private struct Leaf {
    let front: UIViewController
    let back: UIViewController

    init(shot: PageShot, color: UIColor) {
        front = PageFace(shot: shot, color: color)
        back = PageFace(shot: nil, color: color)
    }
}

private final class PageFace: UIViewController {
    private let shot: PageShot?
    private let color: UIColor

    init(shot: PageShot?, color: UIColor) {
        self.shot = shot
        self.color = color
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color
        guard let shot else {
            return
        }
        let image = UIImageView(image: shot.image)
        image.frame = shot.frame
        view.addSubview(image)
    }
}
