//
//  SPBaseCollectionViewCell.swift
//  
//
//  Created by LSP on 2021/1/8.
//

import UIKit

@objc 
class SPBaseCollectionViewCell : UICollectionViewCell {
    deinit {
        self.removeObserver(self, forKeyPath: "reuseIdentifier", context: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addObserver(self, forKeyPath: "reuseIdentifier", options: .new, context: nil)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addObserver(self, forKeyPath: "reuseIdentifier", options: .new, context: nil)
    }
   
    /**
     cell按下的时候是否显示高亮状态.(默认YES)
     */
    @IBInspectable public
    var highlightEnabled: Bool = true

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupSubviews()
    }
    
    /* ***************** 以下为子类重载统一入口 ***************** */
    /**
     *  初始化子视图样式。父类在视图加载时自动调用。
     *  （供子类重载）。
     */
    @objc public
    func setupSubviews() {
        #if DEBUG
        print("%@:子类 -> %@ 重载方法错误. %@", "SPBaseCollectionViewCell", NSStringFromClass(Self.self), "***子类需重载此方法，且无需调用 [super setupSubviews]。***");
        #endif
    }

    /**
     *  cell创建后, 被赋予重用标识符,
     *  若子类需要根据不同的reuseIdentifier设置不同的样式, 可重载本方法.
     *
     *  @param reuseIdentifier 重用标识符
     *  （供子类重载）。
     */
    @objc public
    func configFor(reuseIdentifier: String) {
        // 供子类重载
    }

    /**
     *  确保登录状态, 如果未登录则跳转至登录界面, 并在登录成功后继续之前的操作.
     *
     *  @param failureContinue 登录成功后继续之前的操作
     *  @return 返回是已否登录
     */
    @objc public
    func ensureHadLoginIfFailed(_ failureContinue: () -> Void) -> Bool {
        // 供子类重载
        return false
    }

    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            self.isHighlighted = newValue
        }
    }
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if !self.highlightEnabled {
                return
            }
            let view = self.highlightedView
            if newValue {
                view.alpha = 0.01
                self.contentView.addSubview(view)
            }
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                view.alpha = newValue ? 1.0 : 0.01
            } completion: { finished in
                if !newValue {
                    view.alpha = 1
                    view.removeFromSuperview()
                }
            }
        }
    }
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            _highlightedView?.frame = newValue
        }
    }
    
    private
    var _highlightedView: UIView?
    public
    var highlightedView: UIView {
        if _highlightedView == nil {
            _highlightedView = UIView()
            _highlightedView!.frame = self.bounds;
            _highlightedView!.isUserInteractionEnabled = false
            _highlightedView!.backgroundColor = UIColor(white: 0.6, alpha: 0.3)
        }
        return _highlightedView!
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == nil || keyPath! != "reuseIdentifier"{
            return
        }
        if self.reuseIdentifier == nil {
            return
        }
        
        self.configFor(reuseIdentifier: self.reuseIdentifier!)
    }
}
