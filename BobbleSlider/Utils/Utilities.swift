//
//  Utilities.swift
//  FadingCells
//
//  Created by Tanvi Nabar on 03/02/21.
//

import UIKit

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

extension UIView {
    @discardableResult
    func anchorToSuperview(withInsets insets: UIEdgeInsets = .zero, toSafeArea: Bool = false) -> (topAnchor: NSLayoutConstraint, rightAnchor: NSLayoutConstraint, bottomAnchor: NSLayoutConstraint, leftAnchor: NSLayoutConstraint)? {
        if let superview: UIView = self.superview {
            self.translatesAutoresizingMaskIntoConstraints = false
            var _topAnchor: NSLayoutYAxisAnchor = superview.topAnchor
            var _bottomAnchor: NSLayoutYAxisAnchor = superview.bottomAnchor
            var _leftAnchor: NSLayoutXAxisAnchor = superview.leftAnchor
            var _rightAnchor: NSLayoutXAxisAnchor = superview.rightAnchor
            if toSafeArea {
                _topAnchor = superview.safeAreaLayoutGuide.topAnchor
                _bottomAnchor = superview.safeAreaLayoutGuide.bottomAnchor
                _leftAnchor = superview.safeAreaLayoutGuide.leftAnchor
                _rightAnchor = superview.safeAreaLayoutGuide.rightAnchor
            }
            
            let topAnchor: NSLayoutConstraint = self.topAnchor.constraint(equalTo: _topAnchor, constant: insets.top)
            topAnchor.isActive = true
            
            let rightAnchor: NSLayoutConstraint = self.rightAnchor.constraint(equalTo: _rightAnchor, constant: insets.right)
            rightAnchor.isActive = true
            
            let bottomAnchor: NSLayoutConstraint = self.bottomAnchor.constraint(equalTo: _bottomAnchor, constant: insets.bottom)
            bottomAnchor.isActive = true
            
            let leftAnchor: NSLayoutConstraint = self.leftAnchor.constraint(equalTo: _leftAnchor, constant: insets.left)
            leftAnchor.isActive = true
            
            return (topAnchor: topAnchor, rightAnchor: rightAnchor, bottomAnchor: bottomAnchor, leftAnchor: leftAnchor)
        }
        
        return nil
    }
}

