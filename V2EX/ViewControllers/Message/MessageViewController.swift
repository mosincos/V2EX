import UIKit

class MessageViewController: DataViewController, AccountService {
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(cellWithClass: MessageCell.self)
        view.estimatedRowHeight = 120
        view.rowHeight = UITableViewAutomaticDimension
        view.backgroundColor = .clear
        self.view.addSubview(view)
        view.hideEmptyCells()
        return view
    }()
    
    private weak var replyMessageViewController: ReplyMessageViewController?
    
    private var messages: [MessageModel] = []
    
    private var page = 1, maxPage = 1

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard AccountModel.isLogin else {
            messages.removeAll()
            tableView.reloadData()
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
            return
        }

        /// 有未读通知, 主动刷新
        guard isLoad, let _ = tabBarItem.badgeValue else { return }
        
        fetchNotifications()
    }

//    override func setupSubviews() {
//        if #available(iOS 11.0, *) {
//            navigationController?.navigationBar.prefersLargeTitles = true
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupRefreshView()
    }

    private func setupRefreshView() {

        tableView.addHeaderRefresh { [weak self] in
            self?.fetchNotifications()
        }

        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreNotifications()
        }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func setupRx() {
        
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.LoginSuccessName)
            .subscribeNext { [weak self] _ in
                self?.fetchNotifications()
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
            }.disposed(by: rx.disposeBag)
    }
    
    // MARK: States Handle
    
    override func loadData() {
        fetchNotifications()
    }
    
    func fetchNotifications() {
        guard AccountModel.isLogin else {
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
            return
        }
        
        page = 1
        
        startLoading()
        
        notifications(page: page, success: { [weak self] messages, maxPage in
            guard let `self` = self else { return }
            self.messages = messages
            self.maxPage = maxPage
            self.endLoading()
            self.tableView.reloadData()
            self.tabBarItem.badgeValue = nil
            self.tableView.endHeaderRefresh()
        }) { [weak self] error in
            guard let `self` = self else { return }
            self.errorMessage = error
            self.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            self.tableView.endHeaderRefresh()
            if !self.messages.count.boolValue {
                self.status = .empty
            }
        }
    }
    
    func fetchMoreNotifications() {
        if self.page >= maxPage {
            tableView.endRefresh(showNoMore: true)
            return
        }

        page += 1
        
        startLoading()
        
        notifications(page: page, success: { [weak self] messages, maxPage in
            guard let `self` = self else { return }
            self.messages.append(contentsOf: messages)
            self.tableView.reloadData()
            self.tableView.endRefresh(showNoMore: maxPage < self.page)
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            self?.page -= 1
        }
    }
    
    override func errorView(_ errorView: ErrorView, didTapActionButton _: UIButton) {
        if status == .noAuth {
            presentLoginVC()
            return
        }
        fetchNotifications()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchNotifications()
    }

    override func hasContent() -> Bool {
        return messages.count.boolValue
    }
    
    private func deleteMessages(_ message: MessageModel) {
        guard let id = message.id,
            let once = message.once else {
                HUD.showText("操作失败，无法获取消息 ID 或 once")
                return
        }
        deleteNotification(notifacationID: id, once: once, success: {
            
        }) { error in
            HUD.showText(error)
        }
    }

    private func replyMessage(_ message: MessageModel) {
        if replyMessageViewController == nil {
            let replyMessageVC = ReplyMessageViewController()
            replyMessageVC.view.alpha = 0
            self.replyMessageViewController = replyMessageVC
            addChildViewController(replyMessageVC)
            self.view.addSubview(replyMessageVC.view)
        }
        
        replyMessageViewController?.message = message
    }
}


extension MessageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: MessageCell.self)!
        cell.message = messages[indexPath.row]
        cell.avatarTapHandle = { [weak self] cell in
            guard let `self` = self,
                let row = tableView.indexPath(for: cell)?.row,
                let username = self.messages[row].member?.username else {
                    return
            }
            
            let memberVC = MemberPageViewController(memberName: username)
            self.navigationController?.pushViewController(memberVC, animated: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let topicID = messages[indexPath.row].topic.topicID else { return }
        let topicDetailVC = TopicDetailViewController(topicID: topicID)
        navigationController?.pushViewController(topicDetailVC, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let replyAction = UITableViewRowAction(
            style: .default,
            title: "回复") { _, indexPath in
                let message = self.messages[indexPath.row]
                self.replyMessage(message)
        }
        replyAction.backgroundColor = UIColor.hex(0x0058E5)
        
        let deleteAction = UITableViewRowAction(
            style: .destructive,
            title: "删除") { _, indexPath in
                let message = self.messages.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.deleteMessages(message)
        }
        return [deleteAction, replyAction]
    }
}
