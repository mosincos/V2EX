import Foundation
import UIKit
import SKPhotoBrowser
import SafariServices

public typealias JSONArray = [[String : Any]]
public typealias JSONDictionary = [String : Any]
public typealias Action = () -> Void

//typealias L10n = R.string.localizable

func presentLoginVC() {
    let nav = NavigationViewController(rootViewController: LoginViewController())
    AppWindow.shared.window.rootViewController?.present(nav, animated: true, completion: nil)
}

enum PhotoBrowserType {
    case image(UIImage)
    case imageURL(String)
}

func showImageBrowser(imageType: PhotoBrowserType) {

    var photo: SKPhoto?
    switch imageType {
    case .image(let image):
        photo = SKPhoto.photoWithImage(image)
    case .imageURL(let url):
        photo = SKPhoto.photoWithImageURL(url)
        photo?.shouldCachePhotoURLImage = true
    }
    guard let photoItem = photo else { return }
    SKPhotoBrowserOptions.bounceAnimation = true
    SKPhotoBrowserOptions.enableSingleTapDismiss = true
    SKPhotoBrowserOptions.displayCloseButton = false
    SKPhotoBrowserOptions.displayStatusbar = false
    let photoBrowser = SKPhotoBrowser(photos: [photoItem])
    photoBrowser.initializePageIndex(0)
    photoBrowser.showToolbar(bool: true)
    AppWindow.shared.window.rootViewController?.present(photoBrowser, animated: true, completion: nil)
}

/// 设置状态栏背景颜色
/// 需要设置的页面需要重载此方法
/// - Parameter color: 颜色
func setStatusBarBackground(_ color: UIColor) {
    
    let statusBarWindow : UIView = UIApplication.shared.value(forKey: "statusBarWindow") as! UIView
    let statusBar : UIView = statusBarWindow.value(forKey: "statusBar") as! UIView
    if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
        statusBar.backgroundColor = color
    }
}

/// 打开浏览器 （内置 或 Safari）
///
/// - Parameter url: url
func openWebView(url: URL?) {
    guard let `url` = url else { return }

    var currentVC = AppWindow.shared.window.rootViewController?.currentViewController()
    if currentVC == nil {
        currentVC = AppWindow.shared.window.rootViewController
    }

    if Preference.shared.useSafariBrowser {

        let safariVC = SFSafariViewController(url: url, entersReaderIfAvailable: true) //SFSafariViewController(url: url)
        if #available(iOS 10.0, *) {
            safariVC.preferredControlTintColor = Theme.Color.globalColor
        } else {
            safariVC.navigationController?.navigationBar.tintColor = Theme.Color.globalColor
        }
        currentVC?.present(safariVC, animated: true, completion: nil)
        return
    }
    if let nav = currentVC?.navigationController {
        let webView = SweetWebViewController()
        webView.url = url
        nav.pushViewController(webView, animated: true)
    } else {
        let safariVC = SFSafariViewController(url: url)
        currentVC?.present(safariVC, animated: true, completion: nil)
    }
}

func openWebView(url: String) {
    guard let `url` = URL(string: url) else { return }
    openWebView(url: url)
}

func clickCommentLinkHandle(urlString: String) {
    guard let URL = URL(string: urlString) else { return }
    let link = URL.absoluteString

    if URL.path.contains("/member/") {
        let href = URL.path
        let name = href.lastPathComponent
        let member = MemberModel(username: name, url: href, avatar: "")
        let memberPageVC = MemberPageViewController(memberName: member.username)
        AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(memberPageVC, animated: true)
    } else if URL.path.contains("/t/") {
        let topicID = URL.path.lastPathComponent
        let topicDetailVC = TopicDetailViewController(topicID: topicID)
        AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(topicDetailVC, animated: true)
    } else if URL.path.contains("/go/") {
        let nodeDetailVC = NodeDetailViewController(node: NodeModel(title: "", href: URL.path))
        AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(nodeDetailVC, animated: true)
    } else if link.hasPrefix("https://") || link.hasPrefix("http://"){
        openWebView(url: URL)
    }
}


