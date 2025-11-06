//
//  TaskListViewCell.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import UIKit
import SnapKit

final class TaskListViewCell: UITableViewCell {
    
    static let reuseID = "TaskListViewCell"
    
    //MARK: - GUI variables
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .red
        label.numberOfLines = 0
        
        return label
    }()
    private lazy var checkMarkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle"), for: .selected)
        button.isUserInteractionEnabled = false
        
        return button
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        return label
    }()
    
    private lazy var detailStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.isHidden = true
        return stack
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    
    //MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life cycle
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(roundedRect: self.bounds.insetBy(dx: 16, dy: 4), cornerRadius: 12)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
    
    //MARK: - Public methods
    func configure(with task: Task, isExpanded: Bool) {
        let taskTitle = task.title ?? "No Title"
        
        let attributedString = NSMutableAttributedString(string: taskTitle)
        
        let range = NSRange(location: 0, length: attributedString.length)
        
        if task.isCompleted {
            attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
        } else {
            attributedString.removeAttribute(.strikethroughStyle, range: range)
            attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
        }
        
        titleLabel.attributedText = attributedString
        
        checkMarkButton.isSelected = task.isCompleted
        descriptionLabel.text = task.taskDescription
        
        if let date = task.creationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            dateLabel.text = formatter.string(from: date)
        }
        
        detailStackView.isHidden = !isExpanded
    }
    
    //MARK: - Private methods
    private func setupUI() {
        
        
        detailStackView.addArrangedSubview(descriptionLabel)
        detailStackView.addArrangedSubview(dateLabel)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(detailStackView)
        contentView.addSubview(checkMarkButton)
        contentView.addSubview(mainStackView)

        
        setupConstaints()
    }
    
    private func setupConstaints() {
        checkMarkButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(24)
        }
        
        mainStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalTo(checkMarkButton.snp.trailing).offset(16)
        }
    }
}
