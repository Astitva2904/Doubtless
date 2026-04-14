import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewControllers()
        setupTransparentTabBar()
    }

    private func setupViewControllers() {

        // SOLVE TAB
        let solveVC = SolveViewController()
        let solveNav = SwipeableNavigationController(rootViewController: solveVC)
        solveNav.tabBarItem = UITabBarItem(
            title: "Solve",
            image: UIImage(systemName: "lightbulb"),
            selectedImage: UIImage(systemName: "lightbulb.fill")
        )

        // ACTIVITY TAB
        let activityVC = SolverActivityViewController()
        let activityNav = SwipeableNavigationController(rootViewController: activityVC)
        activityNav.tabBarItem = UITabBarItem(
            title: "Activity",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        // PROFILE TAB
        let profileVC = SolverProfileViewController()
        let profileNav = SwipeableNavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [
            profileNav,
            solveNav,
            activityNav
        ]
    }

    // 🔥 THIS IS THE IMPORTANT PART
    private func setupTransparentTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Remove background & shadow completely
        appearance.backgroundColor = .clear
        appearance.backgroundImage = nil
        appearance.shadowImage = nil
        appearance.shadowColor = nil

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance // 🚨 THIS WAS MISSING BEFORE

        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear

        // Icon colors
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .gray
    }
}
