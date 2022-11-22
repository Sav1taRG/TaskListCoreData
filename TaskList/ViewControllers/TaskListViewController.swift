//
//  TaskListViewController.swift
//  TaskList
//
//  Created by Alexey Efimov on 17.11.2022.
//

import UIKit

class TaskListViewController: UITableViewController {
    
    // MARK: Private Properties
    private let cellID = "task"
    private var taskList: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        fetchData()
    }
    
    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = UIColor(named: "MilkBlue")
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        showAlert(
            withTitle: "New Task",
            andMessage: "What do you want to do?") {[unowned self] task in
                save(task)
            }
    }
    
    private func fetchData() {
        StorageManager.shared.fetchData { result in
            switch result {
            case .success(let taskList):
                self.taskList = taskList
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func showAlert(
        withTitle title: String,
        andMessage message: String,
        taskName: String = "",
        completion: @escaping (String) -> Void
    )
    {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            completion(task)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New Task"
            textField.text = taskName
        }
        present(alert, animated: true)
    }
    
    private func save(_ taskName: String) {
        StorageManager.shared.save(taskName) { task in
            taskList.append(task)
            tableView.insertRows(
                at: [IndexPath(row: taskList.count - 1, section: 0)],
                with: .automatic)
        }
    }
}

// MARK: - UITableView Data Source
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: Edit Task
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let taskInRow = taskList[indexPath.row]
        showAlert(
            withTitle: "Update Task",
            andMessage: "Plans changed?" ,
            taskName: taskInRow.title ?? "") { taskName in
                StorageManager.shared.edit(taskInRow, newName: taskName)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Delete Task
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        
        if editingStyle == .delete {
            taskList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            StorageManager.shared.delete(task)
        }
    }
}
