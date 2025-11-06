//
//  AddTaskViewController.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 04.11.2025.
//

import UIKit
import SnapKit

final class AddTaskViewController: UIViewController {
    
    //MARK: - Properties
    var onTaskSave: ((String, String, Date) -> Void)?
    var taskToEdit: Task?
    
    //MARK: - GUI Variables
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "New Task"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()
    
    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Title"
        tf.borderStyle = .roundedRect
        return tf
        
    }()
    
    private lazy var descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 6
        return tv

    }()
    
    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        return dp
    }()
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        if let task = taskToEdit {
            titleLabel.text = "Edit Task"
            titleTextField.text = task.title
            descriptionTextView.text = task.taskDescription
            datePicker.date = task.creationDate ?? Date()
        }
        
        setupUI()
    }
    
    //MARK: - Private methods
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(titleTextField)
        view.addSubview(descriptionTextView)
        view.addSubview(datePicker)
        view.addSubview(saveButton)
        
        setupConstrainsts()
    }
    
    private func setupConstrainsts() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(16)
            make.leading.trailing.equalTo(titleTextField)
            make.height.equalTo(120)
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(descriptionTextView.snp.bottom).offset(16)
            make.leading.trailing.equalTo(titleTextField)
            
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(24)
            make.leading.trailing.equalTo(titleTextField)
            make.height.equalTo(50)
        }
    }
    
    //MARK: - objc methods
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            return
        }
        let description = descriptionTextView.text ?? ""
        let date = datePicker.date
        
        onTaskSave?(title, description, date)
        dismiss(animated: true)
    }
}
