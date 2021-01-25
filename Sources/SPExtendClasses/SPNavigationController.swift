//
//  SPNavigationController.swift
//  
//
//  Created by LSP on 2021/1/9.
//

import UIKit

open
class SPNavigationController: UINavigationController {
    public
    func pushViewController(_ viewController: UIViewController) {
        super.pushViewController(viewController, animated: true)
    }
    
    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        if self.responds(to: #selector(getter: interactivePopGestureRecognizer)) && animated {
            self.interactivePopGestureRecognizer?.isEnabled = false
        }
        return super.popToViewController(viewController, animated: animated)
    }
    
    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if self.responds(to: #selector(getter: interactivePopGestureRecognizer)) && animated {
            self.interactivePopGestureRecognizer?.isEnabled = false
        }
        return super.popToRootViewController(animated: animated)
    }
    
    private
    var _inPushing = false
    
    
}

