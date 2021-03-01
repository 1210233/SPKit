//
//  SPBaseTableViewCell.swift
//  
//
//  Created by LSP on 2021/1/8.
//

import UIKit
import SPUIKitCategory

@objc open
class SPBaseTableViewCell: UITableViewCell {
   
    /**
     cell按下的时候是否显示高亮状态.(默认YES)
     */
    @IBInspectable public
    var highlightEnabled: Bool = true

    private
    var _lineView: UIView!
    private
    var _separatorframe: CellSeparatorLineFrame = .default
    private
    var _isTheLastInSection = false
    
    override
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupSubviews()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func awakeFromNib() {
        self.setupSubviews()
        if highlightEnabled {
            self.configSelectedBackgroundView()
        }
    }
    
    @objc
    func configSelectedBackgroundView() {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor(hexString: "999999", alpha: 0.3)
        self.selectedBackgroundView = view
    }
    
    open override func setSelected(_ selected: Bool, animated: Bool) {
        self.setHighlighted(selected, animated: animated)
    }
    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if !self.highlightEnabled {
            return
        }
        guard let view = self.selectedBackgroundView else {
            return
        }
        if animated {
            if highlighted {
                view.alpha = 0.01
                self.contentView.addSubview(view)
            }
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                view.alpha = highlighted ? 1 : 0.01
            } completion: { finished in
                if !highlighted {
                    view.alpha = 1
                    view.removeFromSuperview()
                }
            }
        } else {
            if highlighted {
                self.contentView.addSubview(view)
            } else {
                view.removeFromSuperview()
            }
        }
    }
    
    /* ***************** 以下为子类重载统一入口 ***************** */
    /**
     *  初始化子视图样式。父类在视图加载时自动调用。
     *  （供子类重载）。
     */
    @objc public
    func setupSubviews() {
        #if DEBUG
        print(String(format: "%@:子类 -> %@ 重载方法错误. %@", "SPBaseTableViewCell", NSStringFromClass(Self.self), "***子类需重载此方法，且无需调用 [super setupSubviews]。***"))
        #endif
    }
    
    /**
     *  确保登录状态, 如果未登录则跳转至登录界面, 并在登录成功后继续之前的操作.
     *
     *  @param failureContinue 登录成功后继续之前的操作
     *  @return 返回是已否登录
     */
    @objc public
    func ensureHadLoginIfFailed(_ failureContinue: () -> Void) -> Bool {
        // 根据业务逻辑重载
        return false
    }

}


extension SPBaseTableViewCell {
    /// 分割线
    public
    var lineView: UIView? {
        return _lineView
    }
    
    public
    struct SeparatorLineFrame {
        
        /// 左边到父视图的间距
        public var leftSpacing: CGFloat
        /// 右边到父视图的间距
        public var rightSpacing: CGFloat
        /// 垂直方向到父视图的间距
        public var verticalSpacing: CGFloat
        /// 线条高度
        public var height: CGFloat
        
        public static
        let `default`: Self = {
            return Self(l: 0, r: 0, v: 0, h: 0.7)
        }()
        
        public
        enum Position {
            case top
            case bottom
        }
    }
    
    /**
     * 在Cell指定部位添加分割线。
     * position: 指定部位。顶部或底部
     * frame: 尺寸及位置
     */
    public
    func addSeparatorLine(at position: SeparatorLineFrame.Position = .bottom, _ frame: SeparatorLineFrame = .default) {
        
        _separatorframe = frame
        self.addLineView()
        _lineView.leftConstant = frame.leftSpacing
        _lineView.rightConstant = frame.rightSpacing
        
        if position == .top {
            _lineView.topConstant = frame.verticalSpacing
        }else{
            _lineView.bottomConstant = frame.verticalSpacing
        }
        _lineView.heightConstant = frame.height
    }
    
    func addLineView() {
        if _lineView != nil {
            _lineView.removeFromSuperview()
        }
        
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        
        let color = UIColor(white: 0.7, alpha: 0.7)
        if #available(iOS 13.0, *) {
            line.backgroundColor = UIColor(dynamicProvider: { collection -> UIColor in
                if collection.userInterfaceStyle == .dark {
                    return UIColor(white: 0.4, alpha: 0.7)
                } else {
                    return color
                }
            })
        } else {
            line.backgroundColor = color
        }
        
        self.contentView.addSubview(line)
        _lineView = line
    }
   
    /**
     * 是否是Section内最后一个Cell。
     * 如果是最后一个，则lineView的左右保持延长到边。
     */
    public
    var isTheLastInSection: Bool {
        get {
            return _isTheLastInSection
        }
        set {
            _isTheLastInSection = newValue
            if _separatorframe.leftSpacing != 0 {
                self.lineView?.leftConstant = (newValue ? 0 : _separatorframe.leftSpacing)
            }
            if _separatorframe.rightSpacing != 0 {
                self.lineView?.rightConstant = (newValue ? 0 : _separatorframe.rightSpacing)
            }
        }
    }
}

typealias CellSeparatorLineFrame = SPBaseTableViewCell.SeparatorLineFrame
extension CellSeparatorLineFrame: CustomStringConvertible {
    
    public init<T>(l: T, r: T, v: T, h: T) where T: BinaryInteger {
        leftSpacing = CGFloat(l)
        rightSpacing = CGFloat(r)
        verticalSpacing = CGFloat(v)
        height = CGFloat(h)
    }
    public init<T>(l: T, r: T, v: T, h: T) where T: BinaryFloatingPoint {
        leftSpacing = CGFloat(l)
        rightSpacing = CGFloat(r)
        verticalSpacing = CGFloat(v)
        height = CGFloat(h)
    }
    
    public var description: String {
        return String(format: "{L:%.6lf, R:%.6lf, V:%.6lf, H:%.6lf}", leftSpacing, rightSpacing, verticalSpacing, height)
    }
}

// MARK: - ConfigForReuseIdentifier
@objc
extension UITableViewCell {
    /// 需要交换的方法名
    var reuseIdentifierExchangeMethodNames: [String] {
        return ["setReuseIdentifier:"]
    }
    
    func sp_setReuseIdentifier(_ idf: String?) {
        self.sp_setReuseIdentifier(idf)
        if idf != nil {
            self.configFor(reuseIdentifier: idf!)
        }
    }
    
    /**
     *  cell创建后, 被赋予重用标识符,
     *  若子类需要根据不同的reuseIdentifier设置不同的样式, 可重载本方法.
     *
     *  @param reuseIdentifier 重用标识符
     *  （供子类重载）。
     */
    public
    func configFor(reuseIdentifier: String) {
        // 供子类重载
    }
}
