import UIKit

// MARK: - Contrôleur principal
class MainViewController: UIViewController {

    private var floatWindow: FloatingWindow?
    private var isKeyboardVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = UIColor(red:0.06,green:0.06,blue:0.12,alpha:1)

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
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40),
        ])

        // ── Titre ──
        let title = makeLabel("♿ AccessiTools", size: 26, weight: .bold, color: .white)
        let sub   = makeLabel("Clavier flottant  •  Rotation forcée", size: 13, weight: .regular,
                              color: UIColor(white:1,alpha:0.4))
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(sub)
        stack.setCustomSpacing(24, after: sub)

        // ── Bouton clavier ──
        let kbBtn = makeButton("⌨️  Afficher le clavier flottant",
                               bg: UIColor(red:0.42,green:0.27,blue:0.98,alpha:1),
                               fg: .white, tag: 10)
        kbBtn.addTarget(self, action: #selector(toggleKeyboard(_:)), for: .touchUpInside)
        stack.addArrangedSubview(kbBtn)

        let hint = makeLabel("💡 Glisse le clavier vers la partie de l'écran qui marche",
                             size: 12, weight: .regular, color: UIColor(white:1,alpha:0.3))
        hint.numberOfLines = 0
        hint.textAlignment = .center
        stack.addArrangedSubview(hint)
        stack.setCustomSpacing(24, after: hint)

        // ── Section rotation ──
        let rotTitle = makeLabel("FORCER LA ROTATION", size: 10, weight: .semibold,
                                  color: UIColor(white:1,alpha:0.35))
        rotTitle.letterSpacing(1.5)
        stack.addArrangedSubview(rotTitle)

        // Boutons rotation 2x2
        let rot1 = makeRowStack([
            makeRotBtn("⬆️", "Portrait\nnormal",   0),
            makeRotBtn("⬇️", "Portrait\ninversé",  1),
        ])
        let rot2 = makeRowStack([
            makeRotBtn("◀️", "Paysage\ngauche",    2),
            makeRotBtn("▶️", "Paysage\ndroite",    3),
        ])
        stack.addArrangedSubview(rot1)
        stack.addArrangedSubview(rot2)

        let autoBtn = makeButton("🔄  Rotation automatique (par défaut)",
                                  bg: UIColor(white:1,alpha:0.08),
                                  fg: UIColor(white:1,alpha:0.6), tag: 99)
        autoBtn.addTarget(self, action: #selector(resetRotation), for: .touchUpInside)
        stack.addArrangedSubview(autoBtn)
    }

    // MARK: - Keyboard
    @objc private func toggleKeyboard(_ btn: UIButton) {
        isKeyboardVisible.toggle()
        if isKeyboardVisible {
            btn.setTitle("✕  Masquer le clavier", for: .normal)
            btn.backgroundColor = UIColor(red:0.9,green:0.3,blue:0.3,alpha:1)
            showFloatingKeyboard()
        } else {
            btn.setTitle("⌨️  Afficher le clavier flottant", for: .normal)
            btn.backgroundColor = UIColor(red:0.42,green:0.27,blue:0.98,alpha:1)
            hideFloatingKeyboard()
        }
    }

    private func showFloatingKeyboard() {
        let w = FloatingWindow(frame: CGRect(
            x: 10,
            y: UIScreen.main.bounds.height * 0.35,
            width: UIScreen.main.bounds.width - 20,
            height: 260
        ))
        w.windowLevel = .alert + 100
        w.isHidden    = false
        w.makeKeyAndVisible()
        floatWindow = w
    }

    private func hideFloatingKeyboard() {
        floatWindow?.isHidden = true
        floatWindow = nil
    }

    // MARK: - Rotation
    @objc private func handleRotation(_ btn: UIButton) {
        let orientations: [UIDeviceOrientation] = [
            .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight
        ]
        let idx = btn.tag
        guard idx < orientations.count else { return }
        forceOrientation(orientations[idx])

        // Feedback visuel
        UIView.animate(withDuration: 0.15) {
            btn.alpha = 0.5
        } completion: { _ in
            UIView.animate(withDuration: 0.15) { btn.alpha = 1 }
        }
    }

    @objc private func resetRotation() {
        forceOrientation(.unknown)
    }

    private func forceOrientation(_ o: UIDeviceOrientation) {
        UIDevice.current.setValue(o.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }

    // MARK: - Helpers UI
    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight,
                            color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.textAlignment = .center
        return l
    }

    private func makeButton(_ title: String, bg: UIColor, fg: UIColor, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = bg
        b.setTitleColor(fg, for: .normal)
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        b.tag = tag
        return b
    }

    private func makeRotBtn(_ emoji: String, _ label: String, _ tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("\(emoji)\n\(label)", for: .normal)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.textAlignment = .center
        b.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        b.backgroundColor = UIColor(white:1,alpha:0.07)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.layer.borderWidth  = 1
        b.layer.borderColor  = UIColor(white:1,alpha:0.1).cgColor
        b.heightAnchor.constraint(equalToConstant: 72).isActive = true
        b.tag = tag
        b.addTarget(self, action: #selector(handleRotation(_:)), for: .touchUpInside)
        return b
    }

    private func makeRowStack(_ views: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis         = .horizontal
        s.spacing      = 10
        s.distribution = .fillEqually
        return s
    }
}

// MARK: - Fenêtre flottante
class FloatingWindow: UIWindow {
    private var panStart = CGPoint.zero
    private var winStart = CGPoint.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red:0.1,green:0.09,blue:0.16,alpha:0.97)
        layer.cornerRadius  = 16
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowRadius  = 20
        layer.shadowOffset  = CGSize(width:0, height:8)
        layer.borderWidth   = 1
        layer.borderColor   = UIColor(white:1,alpha:0.1).cgColor
        clipsToBounds       = false

        let vc = FloatingKeyboardVC()
        rootViewController = vc

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let screen = UIScreen.main.bounds
        switch g.state {
        case .began:
            panStart = g.location(in: nil)
            winStart = frame.origin
        case .changed:
            let loc   = g.location(in: nil)
            let dx    = loc.x - panStart.x
            let dy    = loc.y - panStart.y
            var nx    = winStart.x + dx
            var ny    = winStart.y + dy
            nx = max(0, min(screen.width  - frame.width,  nx))
            ny = max(20, min(screen.height - frame.height - 20, ny))
            frame.origin = CGPoint(x: nx, y: ny)
        default: break
        }
    }
}

// MARK: - Clavier flottant VC
class FloatingKeyboardVC: UIViewController {

    private let textDisplay = UILabel()
    private var typedText   = ""
    private var isShift     = false
    private var isNums      = false
    private var mainStack   = UIStackView()

    let rows: [[String]]    = [
        ["a","z","e","r","t","y","u","i","o","p"],
        ["q","s","d","f","g","h","j","k","l","m"],
        ["⇧","w","x","c","v","b","n","⌫"],
        ["123","espace","."],
    ]
    let numRows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";","(",")", "€","&","@","\""],
        [".","!","?","'",",","⌫"],
        ["ABC","espace","↵"],
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
    }

    private func setupLayout() {
        // ── Poignée ──
        let handle = UIView()
        handle.backgroundColor = UIColor(white:1,alpha:0.18)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(handle)

        // ── Close ──
        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.setTitleColor(UIColor(white:1,alpha:0.3), for: .normal)
        close.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        close.addTarget(self, action: #selector(dismiss_), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        // ── Affichage texte ──
        textDisplay.text = "  Tape ici…"
        textDisplay.font = UIFont.systemFont(ofSize: 13)
        textDisplay.textColor = UIColor(white:1,alpha:0.6)
        textDisplay.backgroundColor = UIColor(white:1,alpha:0.06)
        textDisplay.layer.cornerRadius = 7
        textDisplay.clipsToBounds = true
        textDisplay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textDisplay)

        // ── Clavier ──
        mainStack.axis    = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: view.topAnchor, constant: 7),
            handle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 36),
            handle.heightAnchor.constraint(equalToConstant: 5),

            close.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            close.widthAnchor.constraint(equalToConstant: 32),
            close.heightAnchor.constraint(equalToConstant: 32),

            textDisplay.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 8),
            textDisplay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textDisplay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textDisplay.heightAnchor.constraint(equalToConstant: 32),

            mainStack.topAnchor.constraint(equalTo: textDisplay.bottomAnchor, constant: 6),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
        ])

        renderKeys()
    }

    private func renderKeys() {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let layout = isNums ? numRows : rows
        for row in layout {
            let rowStack = UIStackView()
            rowStack.axis         = .horizontal
            rowStack.spacing      = 4
            rowStack.distribution = .fill
            for key in row {
                rowStack.addArrangedSubview(makeKey(key))
            }
            mainStack.addArrangedSubview(rowStack)
        }
    }

    private func makeKey(_ key: String) -> UIButton {
        let b = UIButton(type: .system)
        let display = (isShift && !isNums) ? key.uppercased() : key
        b.setTitle(display, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: key.count > 1 ? 11 : 15)
        b.layer.cornerRadius = 6
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
        b.accessibilityLabel = key

        let accent = UIColor(red:0.42,green:0.27,blue:0.98,alpha:1)
        switch key {
        case "⇧":
            b.backgroundColor = isShift ? accent : UIColor(white:1,alpha:0.14)
            b.setTitleColor(.white, for: .normal)
        case "⌫","123","ABC":
            b.backgroundColor = UIColor(white:1,alpha:0.14)
            b.setTitleColor(.white, for: .normal)
        case "espace":
            b.backgroundColor = UIColor(white:1,alpha:0.08)
            b.setTitleColor(UIColor(white:1,alpha:0.4), for: .normal)
            b.setContentHuggingPriority(.defaultLow, for: .horizontal)
            b.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        case "↵":
            b.backgroundColor = accent.withAlphaComponent(0.6)
            b.setTitleColor(.white, for: .normal)
        default:
            b.backgroundColor = UIColor(white:1,alpha:0.08)
            b.setTitleColor(.white, for: .normal)
        }

        b.addTarget(self, action: #selector(keyTap(_:)), for: .touchUpInside)
        return b
    }

    @objc private func keyTap(_ b: UIButton) {
        guard let key = b.accessibilityLabel else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch key {
        case "⇧":  isShift.toggle(); renderKeys()
        case "⌫":
            if !typedText.isEmpty { typedText.removeLast() }
            updateDisplay()
        case "123": isNums = true;  renderKeys()
        case "ABC": isNums = false; renderKeys()
        case "espace": appendText(" ")
        case "↵":      appendText("\n")
        default:
            let c = (isShift && !isNums) ? key.uppercased() : key
            appendText(c)
            if isShift { isShift = false; renderKeys() }
        }
    }

    private func appendText(_ t: String) {
        typedText += t
        updateDisplay()
        UIPasteboard.general.string = typedText
    }

    private func updateDisplay() {
        textDisplay.text = typedText.isEmpty ? "  Tape ici…" : "  " + typedText
    }

    @objc private func dismiss_() {
        // Ferme la fenêtre flottante
        view.window?.isHidden = true
    }
}

// MARK: - Extension label
extension UILabel {
    func letterSpacing(_ s: CGFloat) {
        guard let t = text else { return }
        attributedText = NSAttributedString(string: t, attributes: [
            .kern: s, .foregroundColor: textColor ?? .white,
            .font: font ?? UIFont.systemFont(ofSize: 11)
        ])
    }
}
