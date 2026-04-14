import UIKit

final class DailyTrackerView: UIView {
    
    // MARK: - Header UI Elements
    private let titleLabel = UILabel()
    private let statsLabel = UILabel()
    
    private let collectionView: UICollectionView
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    
    // Data structures
    private var monthlyData: [Int: Int] = [:]
    private var daysInTotal: Int = 365 // We will use something like 180 or 365 depending on VC
    
    // Month overlay header data
    private struct MonthSection {
        let label: String
        let startIndex: Int
    }
    private var monthSections: [MonthSection] = []
    
    // Leetcode colors (Light Mode / Dark Mode adaptive green shades)
    private let colorLevel0 = UIColor.tertiarySystemFill
    private let colorLevel1 = UIColor(red: 172.0/255.0, green: 234.0/255.0, blue: 161.0/255.0, alpha: 1.0)
    private let colorLevel2 = UIColor(red: 104.0/255.0, green: 201.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    private let colorLevel3 = UIColor(red: 48.0/255.0,  green: 161.0/255.0, blue: 78.0/255.0,  alpha: 1.0)
    private let colorLevel4 = UIColor(red: 33.0/255.0,  green: 110.0/255.0, blue: 57.0/255.0,  alpha: 1.0)
    
    override init(frame: CGRect) {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        
        let sideLength: CGFloat = 12
        layout.itemSize = CGSize(width: sideLength, height: sideLength)
        
        // Month headers are placed at the top of the collection view
        layout.headerReferenceSize = CGSize(width: 0, height: 0) // We'll manage months via a custom overlay view above CV
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
        
        // Top Header Row
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .label
        
        statsLabel.font = .systemFont(ofSize: 12, weight: .regular)
        statsLabel.textColor = .secondaryLabel
        statsLabel.textAlignment = .right
        
        let headerHStack = UIStackView(arrangedSubviews: [titleLabel, statsLabel])
        headerHStack.axis = .horizontal
        headerHStack.distribution = .fillProportionally
        headerHStack.alignment = .center
        headerHStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerHStack)
        
        // Collection View Setup
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LeetcodeCell.self, forCellWithReuseIdentifier: "LeetcodeCell")
        collectionView.isScrollEnabled = false // Let the parent scroll view handle scrolling
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // To allow month labels fixed above columns, we use a container
        containerView.addSubview(collectionView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(containerView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            headerHStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            headerHStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerHStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            headerHStack.heightAnchor.constraint(equalToConstant: 20),
            
            scrollView.topAnchor.constraint(equalTo: headerHStack.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            
            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            
            // Collection view takes up the container, minus 20pt on top for Month labels
            // We explicitly force it to 108 height = 7 exactly spaced cells (7*12 + 6*4)
            // so it never calculates 6 cells and mis-aligns the item indices off-screen!
            collectionView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 108)
        ])
    }
    
    func configure(with data: [Int: Int], daysTotal: Int) {
        self.monthlyData = data
        self.daysInTotal = daysTotal
        
        var totalActiveDays = 0
        var totalSubmissions = 0
        var maxStreak = 0
        var currentStreakTrack = 0
        
        // Loop from oldest day (index 1) to newest day (index daysTotal)
        for i in 1...daysTotal {
            let count = data[i] ?? 0
            if count > 0 {
                totalActiveDays += 1
                totalSubmissions += count
                currentStreakTrack += 1
                if currentStreakTrack > maxStreak {
                    maxStreak = currentStreakTrack
                }
            } else {
                currentStreakTrack = 0
            }
        }
        
        // Bold the number in "X submissions in past Year"
        let titleString = NSMutableAttributedString(string: "\(totalSubmissions) ", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold)])
        titleString.append(NSAttributedString(string: "doubts solved", attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.secondaryLabel]))
        titleLabel.attributedText = titleString
        
        // Build stats text
        let statsStr = NSMutableAttributedString()
        statsStr.append(NSAttributedString(string: "Active days: ", attributes: [.foregroundColor: UIColor.secondaryLabel]))
        statsStr.append(NSAttributedString(string: "\(totalActiveDays)", attributes: [.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 12, weight: .bold)]))
        statsStr.append(NSAttributedString(string: "    Max streak: ", attributes: [.foregroundColor: UIColor.secondaryLabel]))
        statsStr.append(NSAttributedString(string: "\(maxStreak)", attributes: [.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 12, weight: .bold)]))
        
        statsLabel.attributedText = statsStr
        
        buildMonthSections(daysTotal: daysTotal)
        collectionView.reloadData()
        
        // Calculate collection view width: (itemsCount / 7 columns) * (12 width + 4 spacing)
        // Ensure minimum 1 width
        let cols = Int(ceil(Double(daysTotal) / 7.0))
        let width = CGFloat(cols) * (12 + 4)
        
        containerView.widthAnchor.constraint(equalToConstant: max(width, bounds.width)).isActive = true
        
        DispatchQueue.main.async {
            self.scrollView.layoutIfNeeded()
            // Auto scroll to the end (today)
            if self.scrollView.contentSize.width > self.scrollView.bounds.width {
                let rightOffset = CGPoint(x: self.scrollView.contentSize.width - self.scrollView.bounds.width, y: 0)
                self.scrollView.setContentOffset(rightOffset, animated: false)
            }
        }
    }
    
    private func buildMonthSections(daysTotal: Int) {
        // Clear old month labels
        containerView.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }
        monthSections.removeAll()
        
        let calendar = Calendar.current
        let today = Date()
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM" // "Jan", "Feb"
        
        var currentMonthString = ""
        var lastLabelMaxX: CGFloat = -100 // Track right-edge collision
        
        for dayIndex in 1...daysTotal {
            // Find the date for this index
            let daysAgo = daysTotal - dayIndex
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let monthString = monthFormatter.string(from: date)
            
            if monthString != currentMonthString {
                currentMonthString = monthString
                
                // Column index = (dayIndex - 1) / 7
                let colIndex = (dayIndex - 1) / 7
                let xPosition = CGFloat(colIndex) * (12 + 4)
                
                // If this label would overlap with the previous label, skip rendering it
                if xPosition >= lastLabelMaxX {
                    let monthLabel = UILabel()
                    monthLabel.text = monthString
                    monthLabel.font = .systemFont(ofSize: 10, weight: .regular)
                    monthLabel.textColor = .secondaryLabel
                    monthLabel.frame = CGRect(x: xPosition, y: 0, width: 30, height: 16)
                    containerView.addSubview(monthLabel)
                    
                    lastLabelMaxX = xPosition + 35 // Reserve 35pt width for this label minimum
                }
            }
        }
    }
}

// MARK: - UICollectionView Data Source
extension DailyTrackerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysInTotal
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LeetcodeCell", for: indexPath) as! LeetcodeCell
        
        // Item index represents days. Since index 0 = day 1 in our data
        let dayIndex = indexPath.item + 1
        let count = monthlyData[dayIndex] ?? 0
        
        cell.configure(count: count, levels: [colorLevel0, colorLevel1, colorLevel2, colorLevel3, colorLevel4])
        return cell
    }
}

// MARK: - Grid Cell
final class LeetcodeCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 2
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(count: Int, levels: [UIColor]) {
        let color: UIColor
        switch count {
        case 0:
            color = levels[0]
        case 1:
            color = levels[1]
        case 2...3:
            color = levels[2]
        case 4...6:
            color = levels[3]
        default:
            color = levels[4]
        }
        backgroundColor = color
        contentView.backgroundColor = color
        
        layer.cornerRadius = 2
        layer.masksToBounds = true
    }
}
