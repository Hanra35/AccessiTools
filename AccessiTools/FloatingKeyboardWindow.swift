import UIKit

// MARK: - Fenêtre du clavier flottant
// Reste visible même quand on quitte l'app (niveau alert maximum)
class FloatingKeyboardWindow: UIWindow {

    // Position de départ du drag
    private var dragStartTouchPos = CGPoint.zero
    private var dragStartWinPos   = CGPoint.zero

    // ── Init ──────────────────────────────────────────────
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWindow()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupWindow() {
        // Niveau très élevé → au-dessus de TOUT (écran accueil inclus)
        windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 9999)

        backgroundColor   = UIColor(red:0.09, green:0.08, blue:0.15, alpha:0.97)
        layer.cornerRadius = 15
        layer.borderWidth  = 1
        layer.borderColor  = UIColor(white:1, alpha:0.1).cgColor
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.75
        layer.shadowRadius  = 22
        layer.shadowOffset  = CGSize(width:0, height:8)
        clipsToBounds = false

        rootViewController = FloatingKeyboardVC()
        isHidden = true
    }

    func show() {
        isHidden = false
        makeKeyAndVisible()
    }

    func hide() {
        isHidden = true
    }

    // ── Drag — CORRIGÉ ────────────────────────────────────
    // On utilise touchesBegan/Moved/Ended directement sur UIWindow
    // pour éviter les problèmes de coordonnées avec UIPanGestureRecognizer

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // Position du toucher DANS la fenêtre
        dragStartTouchPos = touch.location(in: nil)  // coordonnées écran
        dragStartWinPos   = frame.origin
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Position actuelle en coordonnées écran
        let current = touch.location(in: nil)

        // Déplacement par rapport au début
        let dx = current.x - dragStartTouchPos.x
        let dy = current.y - dragStartTouchPos.y

        // Nouvelle position de la fenêtre
        var nx = dragStartWinPos.x + dx
        var ny = dragStartWinPos.y + dy

        // Limite à l'écran (avec marge)
        let scr = UIScreen.main.bounds
        let margin: CGFloat = 8
        nx = max(margin, min(scr.width  - frame.width  - margin, nx))
        ny = max(scr.height * 0.05, min(scr.height - frame.height - margin, ny))

        frame.origin = CGPoint(x: nx, y: ny)

        // NE PAS appeler super → on capture le touch pour le drag
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
}

// MARK: - Contrôleur du clavier flottant
class FloatingKeyboardVC: UIViewController {

    private var typedText  = ""
    private var isShift    = false
    private var isNums     = false
    private let display    = UILabel()
    private let keyStack   = UIStackView()
    private let dragHandle = UIView()

    // AZERTY
    let rows: [[String]]    = [
        ["a","z","e","r","t","y","u","i","o","p"],
        ["q","s","d","f","g","h","j","k","l","m"],
        ["⇧","w","x","c","v","b","n","⌫"],
        ["123","  espace  ","."],
    ]
    let numRows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";","(",")", "@","€","!","?"],
        [".","'","\"",",","_","⌫"],
        ["ABC","  espace  ","↵"],
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildLayout()
    }

    // MARK: - Layout
    private func buildLayout() {
        // ── Barre de drag (en haut) ──────────────────────
        dragHandle.backgroundColor = UIColor(white:1, alpha:0.15)
        dragHandle.layer.cornerRadius = 2.5
        dragHandle.isUserInteractionEnabled = false  // ← laisse les touches passer au UIWindow
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dragHandle)

        let dragHint = UILabel()
        dragHint.text = "≡  Glisse ici pour déplacer"
        dragHint.font = .systemFont(ofSize: 9, weight: .medium)
        dragHint.textColor = UIColor(white:1, alpha:0.25)
        dragHint.textAlignment = .center
        dragHint.isUserInteractionEnabled = false
        dragHint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dragHint)

        // ── Bouton fermer ──
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(UIColor(white:1, alpha:0.35), for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 15)
        closeBtn.addTarget(self, action: #selector(closeKeyboard), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)

        // ── Zone d'affichage du texte ──
        display.text = "  Tape ton texte ici…"
        display.font = .systemFont(ofSize: 13)
        display.textColor = UIColor(white:1, alpha:0.55)
        display.backgroundColor = UIColor(white:1, alpha:0.06)
        display.layer.cornerRadius = 7
        display.clipsToBounds = true
        display.isUserInteractionEnabled = false
        display.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(display)

        // Bouton copier
        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("📋", for: .normal)
        copyBtn.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(copyBtn)

        // ── Clavier ──
        keyStack.axis    = .vertical
        keyStack.spacing = 3
        keyStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyStack)

        // ── Contraintes ──
        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            dragHandle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 40),
            dragHandle.heightAnchor.constraint(equalToConstant: 4),

            dragHint.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 2),
            dragHint.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 28),

            display.topAnchor.constraint(equalTo: dragHint.bottomAnchor, constant: 4),
            display.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            display.trailingAnchor.constraint(equalTo: copyBtn.leadingAnchor, constant: -4),
            display.heightAnchor.constraint(equalToConstant: 30),

            copyBtn.centerYAnchor.constraint(equalTo: display.centerYAnchor),
            copyBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            copyBtn.widthAnchor.constraint(equalToConstant: 30),

            keyStack.topAnchor.constraint(equalTo: display.bottomAnchor, constant: 5),
            keyStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            keyStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            keyStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
        ])

        renderKeys()
    }

    // MARK: - Rendu des touches
    private func renderKeys() {
        keyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let layout = isNums ? numRows : rows

        for row in layout {
            let rowStack = UIStackView()
            rowStack.axis         = .horizontal
            rowStack.spacing      = 3
            rowStack.distribution = .fill

            for key in row {
                let btn = makeKeyButton(key)
                rowStack.addArrangedSubview(btn)
            }
            keyStack.addArrangedSubview(rowStack)
        }
    }

    private func makeKeyButton(_ key: String) -> UIButton {
        let b = UIButton(type: .system)

        // Affichage avec maj si shift actif
        let display = (isShift && !isNums) ? key.uppercased() : key
        b.setTitle(display, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: key.count > 2 ? 10 : 14, weight: .regular)
        b.titleLabel?.numberOfLines = 1
        b.layer.cornerRadius = 5
        b.heightAnchor.constraint(equalToConstant: 34).isActive = true

        // Couleurs selon le type de touche
        let accentColor = UIColor(red:0.42, green:0.27, blue:0.98, alpha:1)
        switch key {
        case "⇧":
            b.backgroundColor = isShift ? accentColor : UIColor(white:1, alpha:0.18)
            b.setTitleColor(.white, for: .normal)
            b.widthAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        case "⌫":
            b.backgroundColor = UIColor(white:1, alpha:0.18)
            b.setTitleColor(.white, for: .normal)
            b.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        case "123", "ABC":
            b.backgroundColor = UIColor(white:1, alpha:0.18)
            b.setTitleColor(.white, for: .normal)
            b.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        case "  espace  ":
            b.backgroundColor = UIColor(white:1, alpha:0.07)
            b.setTitleColor(UIColor(white:1, alpha:0.35), for: .normal)
            // Prend tout l'espace restant
            b.setContentHuggingPriority(.defaultLow, for: .horizontal)
            b.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        case "↵":
            b.backgroundColor = accentColor.withAlphaComponent(0.55)
            b.setTitleColor(.white, for: .normal)
            b.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        default:
            b.backgroundColor = UIColor(white:1, alpha:0.08)
            b.setTitleColor(.white, for: .normal)
        }

        b.accessibilityIdentifier = key   // stocke la vraie clé (pas le display)
        b.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        return b
    }

    // MARK: - Actions
    @objc private func keyPressed(_ btn: UIButton) {
        let key = btn.accessibilityIdentifier ?? ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        switch key {
        case "⇧":
            isShift.toggle()
            renderKeys()

        case "⌫":
            if !typedText.isEmpty {
                typedText.removeLast()
            }
            updateDisplay()

        case "123":
            isNums = true
            renderKeys()

        case "ABC":
            isNums = false
            renderKeys()

        case "  espace  ":
            typedText += " "
            updateDisplay()
            copyToClipboard()

        case "↵":
            typedText += "\n"
            updateDisplay()
            copyToClipboard()

        default:
            let char = (isShift && !isNums) ? key.uppercased() : key
            typedText += char
            updateDisplay()
            copyToClipboard()
            // Désactive le shift après chaque lettre
            if isShift && !isNums {
                isShift = false
                renderKeys()
            }
        }
    }

    @objc private func copyText() {
        copyToClipboard()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Flash visuel
        display.backgroundColor = UIColor(red:0.42, green:0.27, blue:0.98, alpha:0.3)
        UIView.animate(withDuration: 0.4) {
            self.display.backgroundColor = UIColor(white:1, alpha:0.06)
        }
    }

    @objc private func closeKeyboard() {
        AppDelegate.floatingKeyboardWindow?.hide()
        // Remet le bouton dans le MainViewController
        NotificationCenter.default.post(name: .keyboardClosed, object: nil)
    }

    private func updateDisplay() {
        display.text = typedText.isEmpty ? "  Tape ton texte ici…" : "  \(typedText)"
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = typedText
    }
}

// MARK: - Notification
extension Notification.Name {
    static let keyboardClosed = Notification.Name("KeyboardClosed")
}
