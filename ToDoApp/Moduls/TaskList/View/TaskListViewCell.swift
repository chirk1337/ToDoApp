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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with task: Task) {
        titleLabel.text = task.title
        checkMarkButton.isSelected = task.isCompleted
        
        let atributes: [NSAttributedString.Key: Any] = task.isCompleted ?
        [.strikethroughColor: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor.secondaryLabel] :
        [.foregroundColor: UIColor.label]
        
        titleLabel.attributedText = NSAttributedString(string: task.title ?? "", attributes: atributes)
    }
    
    private func setupUI() {
        contentView.addSubview(checkMarkButton)
        contentView.addSubview(titleLabel)
        
        setupConstaints()
    }
    
    private func setupConstaints() {
        checkMarkButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkMarkButton.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }
}
