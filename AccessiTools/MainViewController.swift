import UIKit

// MARK: - Contrôleur principal
class MainViewController: UIViewController {

    private var isKeyboardShown = false
    private let kbToggleBtn = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Interface
    private func setupUI() {
        view.backgroundColor = UIColor(red:0.06, green:0.06, blue:0.12, alpha:1)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -36),
        ])

        // ── Titre ──
        stack.addArrangedSubview(label("♿  AccessiTools", 26, .bold, .white))
        stack.addArrangedSubview(label("Clavier flottant  ·  Rotation globale", 13, .regular,
                                       rgba(1,1,1,0.4)))
        stack.setCustomSpacing(26, after: stack.arrangedSubviews.last!)

        // ══ SECTION CLAVIER ══
        stack.addArrangedSubview(sectionTitle("⌨️  CLAVIER FLOTTANT"))

        kbToggleBtn.setTitle("⌨️   Afficher le clavier", for: .normal)
        kbToggleBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        kbToggleBtn.backgroundColor  = purple
        kbToggleBtn.setTitleColor(.white, for: .normal)
        kbToggleBtn.layer.cornerRadius = 13
        kbToggleBtn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        kbToggleBtn.addTarget(self, action: #selector(toggleKeyboard), for: .touchUpInside)
        stack.addArrangedSubview(kbToggleBtn)

        let kbHint = label("➤ Glisse la barre en haut du clavier pour le déplacer\n➤ Le clavier reste visible même si tu quittes l'app",
                            12, .regular, rgba(1,1,1,0.35))
        kbHint.numberOfLines = 0
        stack.addArrangedSubview(kbHint)
        stack.setCustomSpacing(26, after: kbHint)

        // ══ SECTION ROTATION ══
        stack.addArrangedSubview(sectionTitle("🔄  ROTATION GLOBALE (toutes les apps)"))

        let rotInfo = label("La rotation s'applique à TOUT le système :\nécran d'accueil, apps, partout.",
                             12, .regular, rgba(0.4,0.9,0.6,0.9))
        rotInfo.numberOfLines = 0
        stack.addArrangedSubview(rotInfo)
        stack.setCustomSpacing(10, after: rotInfo)

        // Grille 2×2 de boutons rotation
        let row1 = hStack([
            rotButton("⬆️", "Portrait\nnormal",   .portrait),
            rotButton("⬇️", "Portrait\ninversé",  .portraitFlipped),
        ])
        let row2 = hStack([
            rotButton("◀️", "Paysage\ngauche",    .landscapeLeft),
            rotButton("▶️", "Paysage\ndroite",    .landscapeRight),
        ])
        stack.addArrangedSubview(row1)
        stack.addArrangedSubview(row2)

        // Bouton auto
        let autoBtn = actionButton("🔄   Rétablir la rotation automatique",
                                    bg: rgba(1,1,1,0.07), fg: rgba(1,1,1,0.6))
        autoBtn.addTarget(self, action: #selector(resetRotation), for: .touchUpInside)
        stack.addArrangedSubview(autoBtn)
        stack.setCustomSpacing(26, after: autoBtn)

        // ══ NOTE ══
        let note = label("⚠️  La rotation système nécessite les entitlements TrollStore (déjà inclus dans l'IPA).",
                          11, .regular, rgba(1,0.8,0.2,0.7))
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
    }

    // MARK: - Clavier flottant
    @objc private func toggleKeyboard() {
        isKeyboardShown.toggle()

        if isKeyboardShown {
            kbToggleBtn.setTitle("✕   Masquer le clavier", for: .normal)
            kbToggleBtn.backgroundColor = UIColor(red:0.9, green:0.3, blue:0.3, alpha:1)

            if AppDelegate.floatingKeyboardWindow == nil {
                let scr = UIScreen.main.bounds
                let w = FloatingKeyboardWindow(frame: CGRect(
                    x: 6,
                    y: scr.height * 0.38,
                    width: scr.width - 12,
                    height: 255
                ))
                AppDelegate.floatingKeyboardWindow = w
            }
            AppDelegate.floatingKeyboardWindow?.show()

        } else {
            kbToggleBtn.setTitle("⌨️   Afficher le clavier", for: .normal)
            kbToggleBtn.backgroundColor = purple
            AppDelegate.floatingKeyboardWindow?.hide()
        }
    }

    // MARK: - Rotation SYSTÈME GLOBALE
    @objc private func handleRotation(_ btn: UIButton) {
        guard let ori = SystemOrientation(rawValue: Int32(btn.tag)) else { return }
        applySystemRotation(ori)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Flash visuel
        UIView.animate(withDuration: 0.1, animations: { btn.alpha = 0.4 }) { _ in
            UIView.animate(withDuration: 0.15) { btn.alpha = 1 }
        }
    }

    @objc private func resetRotation() {
        applySystemRotation(.auto)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func applySystemRotation(_ ori: SystemOrientation) {
        // ── Méthode 1 : API privée SpringBoard (TrollStore) ──
        // Cette fonction affecte TOUT le système (écran accueil, toutes les apps)
        SBSSetSystemForcedOrientationLock(ori.rawValue)

        // ── Méthode 2 : fallback UIDevice (affecte seulement cette app) ──
        let deviceOri: UIDeviceOrientation
        switch ori {
        case .auto:            deviceOri = .unknown
        case .portrait:        deviceOri = .portrait
        case .portraitFlipped: deviceOri = .portraitUpsideDown
        case .landscapeLeft:   deviceOri = .landscapeRight
        case .landscapeRight:  deviceOri = .landscapeLeft
        }
        UIDevice.current.setValue(deviceOri.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }

    // MARK: - UI helpers
    private let purple = UIColor(red:0.42, green:0.27, blue:0.98, alpha:1)

    private func rgba(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat) -> UIColor {
        UIColor(red:r, green:g, blue:b, alpha:a)
    }

    private func label(_ t: String,_ sz: CGFloat,_ w: UIFont.Weight,_ c: UIColor) -> UILabel {
        let l = UILabel(); l.text = t
        l.font = .systemFont(ofSize: sz, weight: w)
        l.textColor = c; l.textAlignment = .center; return l
    }

    private func sectionTitle(_ t: String) -> UILabel {
        let l = UILabel(); l.text = t
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = UIColor(white:1, alpha:0.35)
        l.textAlignment = .left; return l
    }

    private func rotButton(_ emoji: String,_ txt: String,_ ori: SystemOrientation) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("\(emoji)\n\(txt)", for: .normal)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.textAlignment  = .center
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        b.backgroundColor  = UIColor(white:1, alpha:0.08)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.layer.borderWidth  = 1
        b.layer.borderColor  = UIColor(white:1, alpha:0.12).cgColor
        b.heightAnchor.constraint(equalToConstant: 74).isActive = true
        b.tag = Int(ori.rawValue)
        b.addTarget(self, action: #selector(handleRotation(_:)), for: .touchUpInside)
        return b
    }

    private func actionButton(_ title: String, bg: UIColor, fg: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.backgroundColor  = bg
        b.setTitleColor(fg, for: .normal)
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return b
    }

    private func hStack(_ views: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal; s.spacing = 10; s.distribution = .fillEqually; return s
    }
}
