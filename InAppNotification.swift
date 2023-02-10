//
//  InAppNotification.swift
//  Toast
//
//  Created by Kavya on 12/05/22.
//

import UIKit

public enum ToastPosition {
    case top
    case bottom
}

public class InAppNotification: UIView {
    
    let imageView = UIImageView()
    let titleLabel = UILabel()
    var position: ToastPosition = .top
    
    var timer: Timer?
    var centreXConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!
    var showConstraint: NSLayoutConstraint?
    var hideConstraint: NSLayoutConstraint?
    let orientation = UIDevice.current.orientation

    private var width: CGFloat {
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            return (self.window?.bounds.height ?? 350) - 16
        }
        return (self.window?.bounds.width ?? 300) - 16
    }
    
    static var isCurrentlyPresenting: Bool {
        if let window = keyWindow() {
            return window.subviews.first(where: { $0 is InAppNotification }) != nil
        }
        return false
    }
    
    init(with message: String, image: UIImage, position: ToastPosition, backgroundColor: UIColor, titleColor: UIColor, font: UIFont) {
        super.init(frame: .zero)
        self.position = position
        self.alpha = 0
        self.isUserInteractionEnabled = true
        self.backgroundColor = backgroundColor
        layer.cornerRadius = 10
        imageView.image = image
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = message
        titleLabel.textColor = titleColor
        titleLabel.numberOfLines = 0
        titleLabel.font = font
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor,constant: -5),
            titleLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 16),
            titleLabel.topAnchor.constraintEqualToSystemSpacingBelow(topAnchor, multiplier: 1)
        ])

        addSwipeGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public static func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).compactMap({$0 as? UIWindowScene}).first?.windows.filter({$0.isKeyWindow}).first
    }
    
    private func show(decayIn: TimeInterval) {
        if let window = InAppNotification.keyWindow() {
            window.addSubview(self)
            window.autoresizesSubviews = true
            translatesAutoresizingMaskIntoConstraints = false
            centreXConstraint = centerXAnchor.constraint(equalTo: window.centerXAnchor)
            heightConstraint =  heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
            widthConstraint = widthAnchor.constraint(equalToConstant: width)
            NSLayoutConstraint.activate([
                widthConstraint,
                centreXConstraint,
                heightConstraint
            ])
            
            switch position {
            case .top:
                showConstraint = topAnchor.constraint(equalTo: window.topAnchor, constant: window.safeAreaInsets.top + 8)
                showConstraint?.isActive = true
                
                hideConstraint = bottomAnchor.constraint(equalTo: window.topAnchor)
                hideConstraint?.isActive = true
                window.layoutIfNeeded()
                hideConstraint?.isActive = false
                
            case .bottom:
                showConstraint = bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -(window.safeAreaInsets.bottom))
                showConstraint?.isActive = true
                
                hideConstraint = topAnchor.constraint(equalTo: window.bottomAnchor, constant: 200)
                hideConstraint?.isActive = true
                window.layoutIfNeeded()
                hideConstraint?.isActive = false
            }

            UIView.animate(withDuration: 0.5) {
                self.alpha = 1
            } completion: { status in
                window.layoutIfNeeded()
            }
            
            timer = Timer.scheduledTimer(timeInterval: decayIn, target: self, selector: #selector(fadeOutView), userInfo: nil, repeats: false)
        }
    }
    
    private func addSwipeGestures() {
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft(_:)))
        swipeLeftGesture.direction = .left
        addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))
        swipeRightGesture.direction = .right
        addGestureRecognizer(swipeRightGesture)
        
        if position == .top {
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp(_:)))
            swipeUpGesture.direction = .up
            addGestureRecognizer(swipeUpGesture)
        }
        
        if position == .bottom {
            let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown(_:)))
            swipeDownGesture.direction = .down
            addGestureRecognizer(swipeDownGesture)
        }
    }
    
    @objc
    private func swipeLeft(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
            self.centreXConstraint.constant -= self.bounds.width
            self.window?.layoutIfNeeded()
        } completion: { status in
            self.removeFromSuperview()
        }
    }
    
    @objc
    private func swipeRight(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
            self.centreXConstraint.constant += self.bounds.width
            self.window?.layoutIfNeeded()
        } completion: { status in
            self.removeFromSuperview()
        }
    }
    
    @objc
    private func swipeUp(_ sender: UISwipeGestureRecognizer) {
        showConstraint?.isActive = false
        hideConstraint?.isActive = true
        UIView.animate(withDuration: 0.2) {
            self.superview?.layoutIfNeeded()
        }completion: { status in
            self.removeFromSuperview()
        }
    }
    
    @objc
    private func swipeDown(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
            self.hideConstraint?.isActive = true
            self.window?.layoutIfNeeded()
        } completion: { status in
            self.removeFromSuperview()
        }
    }
    
    @objc
    private func fadeOutView() {
        UIView.animate(withDuration: 1) {
            self.alpha = 0
        }completion: { status in
            self.removeFromSuperview()
        }
    }
    
    public static func show(message: String, image: UIImage = UIImage(systemName: "r.joystick.tilt.right.fill")!, decayIn: TimeInterval = 4, position: ToastPosition = .top, backGroundColor: UIColor = .lightGray, titleColor: UIColor = .black, font: UIFont = UIFont.systemFont(ofSize: 15, weight: .regular)) {
        InAppNotification(with: message, image: image, position: position, backgroundColor: backGroundColor, titleColor: titleColor, font: font).show(decayIn: decayIn)
    }
}



