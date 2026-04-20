import UIKit

// ═══════════════════════════════════════════════════
//  API PRIVÉE iOS — Rotation système globale
//  Fonctionne avec TrollStore + entitlements spéciaux
// ═══════════════════════════════════════════════════

// Lie la fonction privée de SpringBoard
@_silgen_name("SBSSetSystemForcedOrientationLock")
func SBSSetSystemForcedOrientationLock(_ orientation: Int32)

// Valeurs d'orientation pour SBSSetSystemForcedOrientationLock
// 0 = déverrouillé (auto)
// 1 = Portrait
// 2 = Portrait inversé
// 3 = Paysage gauche
// 4 = Paysage droit
enum SystemOrientation: Int32 {
    case auto            = 0
    case portrait        = 1
    case portraitFlipped = 2
    case landscapeLeft   = 3
    case landscapeRight  = 4
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    // La fenêtre du clavier flottant — persiste en background
    static var floatingKeyboardWindow: FloatingKeyboardWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        // Demande à iOS de rester actif en arrière-plan
        application.beginBackgroundTask(expirationHandler: nil)

        return true
    }

    // Reste actif quand on quitte l'app
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Relance une tâche de fond pour ne pas se faire tuer
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = application.beginBackgroundTask {
            application.endBackgroundTask(bgTask)
        }
        // Garde le clavier flottant visible même en arrière-plan
        AppDelegate.floatingKeyboardWindow?.isHidden = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AppDelegate.floatingKeyboardWindow?.isHidden = false
    }
}
