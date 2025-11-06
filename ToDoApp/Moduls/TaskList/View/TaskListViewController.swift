//
//  TaskListViewController.swift
//  ToDoApp
//
//  Created by Анатолий Чириков on 03.11.2025.
//

import UIKit
import SnapKit

final class TaskListViewController: UIViewController {
    
    //MARK: - Propeties
    private let viewModel: TaskListViewModelProtocol

    //MARK: - GUI Variables
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.searchBarStyle = .minimal
        sb.delegate = self
        return sb
    }()
       
    private lazy var tableView: UITableView = {
        let table = UITableView()
        
        table.delegate = self
        table.dataSource = self
        table.register(TaskListViewCell.self, forCellReuseIdentifier: TaskListViewCell.reuseID)
        //table.separatorStyle = .none
       // table.backgroundColor = .clear
        
        return table
    }()
    
    private lazy var stackView:UIStackView = {
        let stack = UIStackView(arrangedSubviews: [searchBar, tableView])
        stack.axis = .vertical
        stack.spacing = 0
        
        return stack
    }()
    
    
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
        return refresh
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .large)
        activity.hidesWhenStopped = true
        
        return activity
    }()
    
    //MARK: - Init
    init(viewModel: TaskListViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        
        viewModel.viewDidLoad()
    }
    
    //MARK: - Private methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "My Tasks"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        navigationItem.titleView = titleLabel
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
       
       // view.addSubview(searchBar)
        //view.addSubview(tableView)
        
        view.addSubview(stackView)
        view.addSubview(addButton)
        view.addSubview(refreshControl)
        view.addSubview(loadingView)
        
        setupConstrainsts()
    }
    
    
    
    private func setupConstrainsts() {
        //searchBar.snp.makeConstraints { make in
          //  make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
          //  make.leading.trailing.equalToSuperview().inset(8)
       // }
        
       // tableView.snp.makeConstraints { make in
        //    make.top.equalTo(searchBar.snp.bottom)
         //   make.leading.trailing.equalToSuperview()
       // }
        //tableView.snp.makeConstraints { make in
             //   make.edges.equalTo(view.safeAreaLayoutGuide)
           // }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.size.equalTo(56)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        var viewModel = self.viewModel
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    if !(self?.refreshControl.isRefreshing ?? false) {
                        self?.refreshControl.beginRefreshing()
                    }
                } else {
                    self?.refreshControl.endRefreshing()
                }
            }
        }
        
        viewModel.onDataUpdated = { [weak self] in
            print("➡️ ViewController: Received onDataUpdated call from ViewModel. Reloading table view...")

            self?.tableView.reloadData()
        }
        
        viewModel.onError = { [weak self] errorMessage in
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive))
            self?.present(alert, animated: true)
        }
    }
    
    //MARK: - objc methods
    @objc private func addButtonTapped() {
        viewModel.addNewTaskTapped()
    }
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }


}

//MARK: - TableView Data source
extension TaskListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let sections = viewModel.getNumberOfSections()

        print("📋 DataSource: numberOfSections = \(sections)")
        return sections
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGray6
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.text = viewModel.getTitle(for: section)
        
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSectionHeaderTap(_:)))
        headerView.tag = section
        headerView.addGestureRecognizer(tapGesture)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    @objc private func handleSectionHeaderTap(_ recognizer: UITapGestureRecognizer) {
        guard let section = recognizer.view?.tag else { return }
        viewModel.toggleSectionCollapse(for: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = viewModel.getNumberOfRows(in: section)

        print("📋 DataSource: numberOfRowsInSection \(section) = \(rows)")
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskListViewCell.reuseID, for: indexPath) as? TaskListViewCell else {
            return UITableViewCell()
        }
        let task = viewModel.getTask(at: indexPath)
        let isExpanded = viewModel.expandedIndexPath == indexPath
        cell.configure(with: task, isExpanded: isExpanded)
        return cell
    }
}

//MARK: - TableView Delegate
extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        viewModel.toggleCellExpansion(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let completeAction = UIContextualAction(style: .normal, title: "Complete") { [weak self] _, _, completion in
            self?.viewModel.markTaskAsCompleted(at: indexPath)
            completion(true)
        }
        completeAction.image = UIImage(systemName: "checkmark")
        completeAction.backgroundColor = .systemGreen
        
        let task = viewModel.getTask(at: indexPath)
        return task.isCompleted ? nil : UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.viewModel.deleteTask(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.viewModel.editTask(at: indexPath)
            completion(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}
//MARK: - SearchBar delegate
extension TaskListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchTasks(witn: searchText)
    }
}
