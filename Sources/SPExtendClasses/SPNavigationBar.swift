//
//  SPNavigationBar.swift
//  
//
//  Created by LSP on 2021/1/9.
//

import UIKit

open
class SPNavigationBar: UINavigationBar {
    public override
    init(frame: CGRect) {
        super.init(frame: frame)
        self.titleTextAttributes = [.foregroundColor: UIColor(white: 0.3, alpha: 1), .font: UIFont.boldSystemFont(ofSize: 18)]
    }
    
    required public
    init?(coder: NSCoder) {
        super.init(coder: coder)
        self.titleTextAttributes = [.foregroundColor: UIColor(white: 0.3, alpha: 1), .font: UIFont.boldSystemFont(ofSize: 18)]
    }
    
    open override
    var isTranslucent: Bool {
        get {
            return false
        }
        set { }
    }
    
    open override
    var barStyle: UIBarStyle {
        get {
            return .default
        }
        set {}
    }
}
