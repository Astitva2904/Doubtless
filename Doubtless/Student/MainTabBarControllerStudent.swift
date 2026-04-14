import UIKit

final class MainTabBarControllerStudent: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTransparentTabBar()
    }

    private func setupViewControllers() {

        // ➕ HOME / UPLOAD DOUBT TAB
        let uploadVC = UploadDoubtViewController()
        let uploadNav = SwipeableNavigationController(rootViewController: uploadVC)
        uploadNav.tabBarItem = UITabBarItem(
            title: "Upload",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )

        // 📊 ACTIVITY TAB
        let activityVC = StudentActivityViewController()
        let activityNav = SwipeableNavigationController(rootViewController: activityVC)
        activityNav.tabBarItem = UITabBarItem(
            title: "Activity",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        // 👤 PROFILE TAB
        let profileVC = StudentProfileViewController()
        let profileNav = SwipeableNavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [
            profileNav,
            uploadNav,
            activityNav
        ]
    }

    // 🔥 TRANSPARENT / FLOATING TAB BAR (MATCHES YOUR OTHER CODE)
    private func setupTransparentTabBar() {

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Remove background & shadow completely
        appearance.backgroundColor = .clear
        appearance.backgroundImage = nil
        appearance.shadowImage = nil
        appearance.shadowColor = nil

        // Apply appearance
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance   // ⚠️ VERY IMPORTANT

        // Final touches
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear

        // Optional: icon colors
        tabBar.tintColor = .systemOrange
        tabBar.unselectedItemTintColor = .gray
    }
}
