import UIKit

public enum FAQUserType {
    case student
    case solver
}

struct FAQItem {
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

final class FAQViewController: UIViewController {
    
    private let userType: FAQUserType
    private var faqs: [FAQItem] = []
    
    private let tableView = UITableView()
    
    init(type: FAQUserType) {
        self.userType = type
        super.init(nibName: nil, bundle: nil)
        setupData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FAQs"
        view.backgroundColor = .systemBackground
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    
    // Setup data based on type
    private func setupData() {
        if userType == .student {
            faqs = [
                FAQItem(question: "1. What is Doubtless?", answer: "Doubtless is a platform where students can clear their academic doubts by connecting with verified college solvers through one-to-one live video sessions."),
                FAQItem(question: "2. How do I post a doubt?", answer: "Tap the Upload tab, select your subject and language, type your question or attach an image, and submit. Your doubt will be sent to available solvers."),
                FAQItem(question: "3. What are Creds?", answer: "Creds are the in-app currency used to pay for sessions. 1 Cred = ₹1 in value. You can purchase Creds from the Creds Store on your profile."),
                FAQItem(question: "4. How much does a session cost?", answer: "Each doubt-solving session costs a flat 30 Creds. However, if the session is under 2 minutes, it is completely free — no Creds are deducted."),
                FAQItem(question: "5. Do I get any free Creds?", answer: "Yes! Every new student receives 60 free Creds upon signing up — enough for 2 sessions to try the platform."),
                FAQItem(question: "6. How do I buy more Creds?", answer: "Go to your Profile → Creds Store. You can purchase packs of 100, 300, or 600 Creds securely through Apple's In-App Purchase system."),
                FAQItem(question: "7. Can I upload images of my doubts?", answer: "Yes. You can upload images, screenshots, or photos of handwritten questions while posting your doubt."),
                FAQItem(question: "8. What if no solver accepts my doubt?", answer: "If no solver accepts within 15 minutes, the doubt expires automatically. No Creds are deducted. You can resubmit anytime."),
                FAQItem(question: "9. Is the session private?", answer: "Yes. Each session is a private one-to-one video interaction between you and the solver."),
                FAQItem(question: "10. What subjects are supported?", answer: "Currently, Doubtless supports Mathematics, Physics, and Chemistry."),
                FAQItem(question: "11. Are refunds available?", answer: "Creds purchases are processed through Apple and are subject to Apple's refund policy. If a session had technical issues, contact us at contactusdoubtless@gmail.com."),
                FAQItem(question: "12. How do I delete my account?", answer: "Go to Settings → Delete Account. This will permanently remove all your data including Creds balance.")
            ]
        } else {
            faqs = [
                FAQItem(question: "1. Who is a solver?", answer: "A solver is a verified college student who helps fellow students resolve their academic doubts through one-to-one live video sessions and earns money for it."),
                FAQItem(question: "2. How do I receive doubt requests?", answer: "When a student uploads a doubt in your subject, it appears in your Solve feed. You can review the question and accept it."),
                FAQItem(question: "3. What happens after I accept a request?", answer: "A one-to-one live video session begins with the student. You explain the solution and help clarify their doubt."),
                FAQItem(question: "4. How much do I earn per session?", answer: "You earn ₹20.40 for every completed session that lasts over 2 minutes. Sessions under 2 minutes are free for the student and no earnings are generated."),
                FAQItem(question: "5. How do I withdraw my earnings?", answer: "Go to your Profile → Withdraw Earnings. Enter your UPI ID and tap Withdraw. Payouts are processed via UPI and typically arrive within 24 hours."),
                FAQItem(question: "6. What is the minimum withdrawal amount?", answer: "You need at least ₹1 in pending earnings to request a withdrawal."),
                FAQItem(question: "7. Can I decline a doubt request?", answer: "Yes. If the question is outside your expertise or you are unavailable, you can skip the request. There is no penalty."),
                FAQItem(question: "8. Can I solve multiple doubts in a day?", answer: "Absolutely! You can accept and solve unlimited doubts depending on your availability. The more you solve, the more you earn."),
                FAQItem(question: "9. What if the student does not join?", answer: "If the student does not join within the expected time, the session is cancelled automatically. No earnings are affected."),
                FAQItem(question: "10. Is the session private?", answer: "Yes. Each session is a private one-to-one video call between you and the student."),
                FAQItem(question: "11. How do I delete my account?", answer: "Go to Settings → Delete Account. This will permanently remove all your data including earnings history.")
            ]
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FAQCell.self, forCellReuseIdentifier: FAQCell.identifier)
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension FAQViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.identifier, for: indexPath) as? FAQCell else {
            return UITableViewCell()
        }
        cell.configure(with: faqs[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        faqs[indexPath.row].isExpanded.toggle()
        
        // Deselect row and reload it to animate expansion
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

final class FAQCell: UITableViewCell {
    
    static let identifier = "FAQCell"
    
    private let containerView = UIView()
    private let stackView = UIStackView()
    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let arrowImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        questionLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        
        answerLabel.font = .systemFont(ofSize: 14)
        answerLabel.textColor = .secondaryLabel
        answerLabel.numberOfLines = 0
        answerLabel.isHidden = true
        
        arrowImageView.image = UIImage(systemName: "chevron.down")
        arrowImageView.tintColor = .systemGray
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowImageView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Fixed size so the chevron never gets compressed
        NSLayoutConstraint.activate([
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        let headerStack = UIStackView(arrangedSubviews: [questionLabel, arrowImageView])
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .top
        
        stackView.addArrangedSubview(headerStack)
        stackView.addArrangedSubview(answerLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with item: FAQItem) {
        questionLabel.text = item.question
        answerLabel.text = item.answer
        
        answerLabel.isHidden = !item.isExpanded
        arrowImageView.image = UIImage(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
    }
}
