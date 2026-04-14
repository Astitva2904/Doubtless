//
//  AppDelegate.swift
//  DoubtLess
//
//  Created by admin34 on 06/11/25.
//

import UIKit


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Apply global text view overrides (Turn off autocorrect and predictive text everywhere)
        GlobalTextInputOverrides.apply()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

// MARK: - Global Text Input Config
public struct GlobalTextInputOverrides {
    
    public static func apply() {
        swizzleWillMove(for: UITextField.self, swizzledSelector: #selector(UITextField.doubtless_willMove(toSuperview:)))
        swizzleWillMove(for: UITextView.self, swizzledSelector: #selector(UITextView.doubtless_willMove(toSuperview:)))
    }
    
    private static func swizzleWillMove(for cls: AnyClass, swizzledSelector: Selector) {
        let originalSelector = #selector(UIView.willMove(toSuperview:))
        
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
              let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector) else {
            return
        }
        
        // Since we are swizzling a method from a superclass (UIView) on a subclass (UITextField/View),
        // we should add the method to the subclass first in case it doesn't override it yet.
        let didAddMethod = class_addMethod(cls,
                                           originalSelector,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(cls,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UITextField {
    @objc dynamic func doubtless_willMove(toSuperview newSuperview: UIView?) {
        // Call original implementation
        self.doubtless_willMove(toSuperview: newSuperview)
        
        // Disable autocorrection and spell checking globally
        self.autocorrectionType = .no
        self.spellCheckingType = .no
        self.smartQuotesType = .no
        self.smartDashesType = .no
        self.smartInsertDeleteType = .no
    }
}

extension UITextView {
    @objc dynamic func doubtless_willMove(toSuperview newSuperview: UIView?) {
        // Call original implementation
        self.doubtless_willMove(toSuperview: newSuperview)
        
        // Disable autocorrection and spell checking globally
        self.autocorrectionType = .no
        self.spellCheckingType = .no
        self.smartQuotesType = .no
        self.smartDashesType = .no
        self.smartInsertDeleteType = .no
    }
}
