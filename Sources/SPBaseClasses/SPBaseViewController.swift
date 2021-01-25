//
//  SPBaseViewController.swift
//  
//
//  Created by LSP on 2021/1/9.
//

import UIKit

open
class SPBaseViewController: UIViewController, UIGestureRecognizerDelegate {
    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        print("-[\(Self.self) dealloc]")
        #endif
    }
    
    open override
    func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.setupSubviews()
        self.setupNavigationItems()
        self.initialization()
        
        if self.navigationController != nil, let delegate = self.navigationController!.interactivePopGestureRecognizer?.delegate as? UIViewController, delegate != self.navigationController! {
            self.navigationController!.interactivePopGestureRecognizer?.delegate = self
        }
        
        self.sp_registerNotifications()
        
        if self.view.backgroundColor == nil {
            self.view.backgroundColor = UIColor.white
        }
        
        if #available(iOS 11.0, *) {
            for selName in ["scrollView", "tableView", "collectionView"] {
                let selector = Selector(selName)
                
                if self.responds(to: selector) {
                    if let object = self.perform(selector), let scrollView = object.takeUnretainedValue() as? UIScrollView {
                        scrollView.contentInsetAdjustmentBehavior = .never
                        
                        if let tableView = scrollView as? UITableView {
                            tableView.estimatedRowHeight = 0
                            tableView.estimatedSectionHeaderHeight = 0
                            tableView.estimatedSectionFooterHeight = 0
                        }
                    }
                }
            }
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    #if DEBUG
    open
    func setupSubviews() {
        print("SPBaseViewController:子类 -> \(Self.self) 重载方法错误. ***子类需重载此方法，且无需调用 [super setupSubviews]。***")
    }
    open
    func setupNavigationItems() {
        print("SPBaseViewController:子类 -> \(Self.self) 重载方法错误. ***子类需重载此方法，且无需调用 [super setupNavigationItems]。***")
    }
    open
    func initialization() {
        print("SPBaseViewController:子类 -> \(Self.self) 重载方法错误. ***子类需重载此方法，且无需调用 [super initialization]。***")
    }
    #else
    open
    func setupSubviews() {
        // ***子类需重载此方法，且无需调用 [super setupSubviews]。***
    }
    open
    func setupNavigationItems() {
        // ***子类需重载此方法，且无需调用 [super setupNavigationItems]。***
    }
    open
    func initialization() {
        // ***子类需重载此方法，且无需调用 [super initialization]。***
    }
    #endif

    
    func sp_registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshHandle(_:)), name: NSNotification.Name(rawValue: "\(Self.self)"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessHandle(_:)), name: NSNotification.Name(rawValue: "UserLoginSuccessNotification"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(showLoginView), name: NSNotification.Name(rawValue: ""), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogout), name: NSNotification.Name(rawValue: "UserLogouCompleteNotification"), object: nil)
    }
    
    @objc
    func refreshHandle(_ notification: Notification) {
        if self.isViewLoaded {
            self.refreshContent(notification)
        }
    }
    
    open
    func refreshContent(_ notification: Notification) {
        // 供子类实现.
    #if DEBUG
        print("Hanlde a notification for \(Self.self), you need override refreshContent(_:) to refresh your content.");
    #endif
    }
    
    public
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.navigationController != nil, let gesture = self.navigationController!.interactivePopGestureRecognizer {
            if gestureRecognizer == gesture {
                return self.navigationController!.viewControllers.count > 1
            }
        }
        return true
    }
}

var sp_firstAppearKey = "sp_firstAppearKey"


@objc
extension UIViewController {
    @objc open
    var canSerialPush: Bool {
        return true
    }
    
    #if DEBUG
    /// 需要交换的方法名
    var viewDidAppearExchangeMethodNames: [String] {
        return ["viewDidAppear:"]
    }
    func sp_viewDidAppear(_ animated: Bool) {
        if let firstAppear = objc_getAssociatedObject(self, &sp_firstAppearKey) as? NSNumber, firstAppear.boolValue {
        } else {
            objc_setAssociatedObject(self, &sp_firstAppearKey, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            print("-[\(Self.self) firstAppear]")
        }
        self.sp_viewDidAppear(animated)
    }
    #endif
}



extension SPBaseViewController {
//    @objc open
    open override
    var canSerialPush: Bool {
        return false
    }
    /**
     *  返回上一级控制器。
     */
    @IBAction public
    func backViewController() {
        if let navi = self.navigationController {
            if navi.viewControllers.count == 1 {
                if navi.presentingViewController != nil {
                    navi.dismiss(animated: true, completion: nil)
                }
            } else if navi.viewControllers.count == 2 {
                if #available(iOS 14.0, *) {
                    navi.topViewController?.hidesBottomBarWhenPushed = false
                }
                navi.popToRootViewController(animated: true)
            } else if navi.viewControllers.count > 2 {
                let pre = navi.viewControllers[navi.viewControllers.count - 2]
                if #available(iOS 14.0, *) {
                    navi.topViewController?.hidesBottomBarWhenPushed = false
                }
                navi.popToViewController(pre, animated: true)
            }
        } else if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public
    func pushViewController(_ vc: UIViewController?) {
        guard let viewController = vc else {
            return
        }
        
        
        guard let navi = self.navigationController else {
            var navi: UINavigationController!
            if viewController is SPBaseViewController {
                navi = SPNavigationController(rootViewController: viewController)
            } else {
                navi = UINavigationController(rootViewController: viewController)
            }
            self.present(navi, animated: true, completion: nil)
            
            return
        }
        
        if let lastVC = navi.viewControllers.last, lastVC.classForCoder == viewController.classForCoder {
            
            if !viewController.canSerialPush {
                return
            }
        }
        
        if let n = navi as? SPNavigationController {
            n.pushViewController(viewController)
        } else {
            navi.pushViewController(viewController, animated: true)
        }
    }
    
    @objc public
    func showLoginView() {
        if self.view.window != nil {
            self.gotoLogin(success: nil)
        }
    }
    
    @objc open
    func userDidLogout() {
        // 供子类重载
    }
    
    open
    func gotoLogin(success callback: (() -> Void)?) {
        // 供子类重载
    }
    
    open
    func ensureHadLoginIfFailed(_ failureContinue: (() -> Void)?) -> Bool {
//    if User.hasLogin {
//        return true
//    }
//    self.gotoLoginAndSuccessCallback(failureContinue)
        // 供子类重载
        return false
    }
    
    public
    func ensureHadLoginExecute(_ execute: @escaping () -> Void) {
        if self.ensureHadLoginIfFailed(execute) {
            execute()
        }
    }
    
    @objc public
    func loginSuccessHandle(_ notification: Notification) {
        if self.isViewLoaded {
            self.loginSuccessNotification(notification)
        }
    }
    open
    func loginSuccessNotification(_ notification: Notification) {
        
    }
}

// MARK: 利用通知刷新其他控制器
extension SPBaseViewController {
    public
    func refreshViewController(_ cls: AnyClass, userInfo: [AnyHashable: Any]? = nil) {
        self.refreshViewControllers([cls], userInfo: userInfo)
    }
    public
    func refreshViewControllers(_ classes: [AnyClass], userInfo: [AnyHashable: Any]? = nil) {
        let nc = NotificationCenter.default
        for cls in classes {
            let noti = Notification(name: NSNotification.Name(rawValue: "\(cls)"), object: self, userInfo: userInfo)
            nc.post(noti)
        }
    }
    public
    func refreshViewController(_ name: String, userInfo: [AnyHashable: Any]? = nil) {
        self.refreshViewControllers([name], userInfo: userInfo)
    }
    public
    func refreshViewControllers(_ names: [String], userInfo: [AnyHashable: Any]? = nil) {
        let nc = NotificationCenter.default
        for name in names {
            if name.isEmpty {
                continue
            }
            let noti = Notification(name: NSNotification.Name(rawValue: name), object: self, userInfo: userInfo)
            nc.post(noti)
        }
    }
}

extension SPBaseViewController {
     public
    func callPhone(_ phone: String) -> Bool {
        if phone.isEmpty {
            return false
        }
        if let url = URL(string: "TEL://" + phone),
           UIApplication.shared.canOpenURL(url) {
            return UIApplication.shared.openURL(url)
        }
        return false
    }
}
