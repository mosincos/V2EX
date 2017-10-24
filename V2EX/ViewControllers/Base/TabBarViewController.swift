import UIKit
import RxSwift
import RxCocoa
import RxOptional

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAppearance()
        setupTabBar()
        clickBackTop()
        listenNotification()
    }
    
    func listenNotification() {
        
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.UnreadNoticeName)
            .subscribeNext { [weak self] notification in
                guard let count = notification.object as? Int else {
                    return
                }
                
                // 消息控制器显示 badge
                self?.childViewControllers.forEach({ viewController in
                    if viewController.isKind(of: NavigationViewController.self),
                        let nav = viewController as? NavigationViewController,
                        let topVC = nav.topViewController,
                        topVC.isKind(of: MessageViewController.self) {
                        viewController.tabBarItem.badgeValue = count.description
                    }
                })
            }.disposed(by: rx.disposeBag)
    }
}

extension TabBarViewController {
    
    fileprivate func setAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor : UIColor.hex(0x8a8a8a)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor : Theme.Color.globalColor], for: .selected)
    }
    
    fileprivate func setupTabBar() {
        
        addChildViewController(childController: HomeViewController(),
                               title: "首页",
                               normalImage: #imageLiteral(resourceName: "list"),
                               selectedImageName: #imageLiteral(resourceName: "list_selected"))

        addChildViewController(childController: NodesViewController(),
                               title: "节点",
                               normalImage: #imageLiteral(resourceName: "navigation"),
                               selectedImageName: #imageLiteral(resourceName: "navigation_selected"))

        addChildViewController(childController: MessageViewController(),
                               title: "消息",
                               normalImage: #imageLiteral(resourceName: "notifications"),
                               selectedImageName: #imageLiteral(resourceName: "notifications_selected"))

        addChildViewController(childController: MoreViewController(),
                               title: "更多",
                               normalImage: #imageLiteral(resourceName: "more"),
                               selectedImageName: #imageLiteral(resourceName: "more_selected"))
    }
    
    fileprivate func addChildViewController(childController: UIViewController, title: String, normalImage: UIImage?, selectedImageName: UIImage?) {
        childController.tabBarItem.image = normalImage?.withRenderingMode(.alwaysOriginal)
        childController.tabBarItem.selectedImage = selectedImageName?.withRenderingMode(.alwaysOriginal)
        childController.title = title
        addChildViewController(NavigationViewController(rootViewController: childController))
    }
    
    fileprivate func clickBackTop() {
        self.rx.didSelect
            .scan((nil, nil)) { state, viewController in
                return (state.1, viewController)
            }
            // 如果第一次选择视图控制器或再次选择相同的视图控制器
            .filter { state in state.0 == nil || state.0 === state.1 }
            .map { state in state.1 }
            .filterNil()
            .subscribe(onNext: { [weak self] viewController in
                self?.scrollToTop(viewController)
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    fileprivate func scrollToTop(_ viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            let topViewController = navigationController.topViewController
            let firstViewController = navigationController.viewControllers.first
            if let viewController = topViewController, topViewController === firstViewController {
                self.scrollToTop(viewController)
            }
            return
        }
        guard let scrollView = viewController.view.subviews.first as? UIScrollView else { return }
        scrollView.scrollToTop()
    }
}
