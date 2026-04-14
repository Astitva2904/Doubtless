import UIKit

/// A UINavigationController subclass that keeps the interactive pop gesture
/// (swipe-back) enabled even when:
///   - The navigation bar is hidden
///   - A custom leftBarButtonItem replaces the system back button
///
/// Usage: Replace `UINavigationController(rootViewController:)` with
///        `SwipeableNavigationController(rootViewController:)`.
final class SwipeableNavigationController: UINavigationController,
                                            UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    // MARK: - UIGestureRecognizerDelegate

    /// Allow the gesture only when there is more than one VC on the stack
    /// (prevents a freeze if you swipe on the root VC).
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }

    /// Don't let the pop gesture conflict with other gestures (scroll views, etc.)
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
