import UIKit
import Supabase
import Auth


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Try to restore the session immediately without showing splash animation.
        // This prevents the onboarding animation from replaying every time
        // iOS destroys and recreates the scene (common on real devices).
        Task {
            let user = try? await SupabaseManager.shared.getCurrentUser()

            await MainActor.run {
                if let user = user {
                    // User is already logged in — skip splash, go directly to dashboard
                    let savedRole = UserDefaults.standard.string(forKey: "selectedRole") ?? "student"
                    let rootVC: UIViewController

                    if savedRole == "solver" {
                        if let roleStatus = user.userMetadata["role"]?.stringValue, roleStatus == "solver" {
                            rootVC = MainTabBarController()
                        } else {
                            rootVC = SolverDocumentUploadViewController()
                        }
                    } else {
                        rootVC = MainTabBarControllerStudent()
                    }

                    let nav = SwipeableNavigationController(rootViewController: rootVC)
                    nav.navigationBar.isHidden = true
                    window.rootViewController = nav
                } else {
                    // Not logged in — show the full splash + onboarding flow
                    let splashVC = SplashViewController()
                    window.rootViewController = splashVC
                }

                window.makeKeyAndVisible()
            }
        }

        // Show a plain background while the async session check runs,
        // so the user doesn't see a black screen.
        let loadingVC = UIViewController()
        loadingVC.view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
        window.rootViewController = loadingVC
        window.makeKeyAndVisible()
    }

    // MARK: - Scene Lifecycle

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is released by the system.
        // Release any resources that were specific to the discarded scene.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene moves from inactive to active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene moves from active to inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from background to foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from foreground to background.
    }

    // MARK: - Deep Link Interception for Supabase OAuth
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // Let the Supabase Session hook up the login securely from the callback!
        if url.scheme == "doubtless" {
            Task {
                do {
                    try await SupabaseManager.shared.client.auth.session(from: url)
                } catch {
                    print("Could not restore session from deep link URL: \(error)")
                }
            }
        }
    }
}
