//
//  AMAlertView.swift
//  AMAppkit
//
//  Created by Ilya Kuznetsov on 12/16/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public class AMAlert: NSObject {
    
    fileprivate static let shared = AMAlert()
    
    @objc public static let defaultTitle: String = Bundle().infoDictionary!["CFBundleDisplayName"] as? String ?? Bundle().infoDictionary!["CFBundleName"] as! String
    
    @objc public static func present(_ message: String?, on viewController: UIViewController) -> UIAlertController {
        return present(title: defaultTitle, message: message, on: viewController)
    }
    
    @objc public static func present(title: String?, message: String?, on viewCotnroller: UIViewController) -> UIAlertController {
        return present(title: title, message: message, cancel: ("OK", nil), other: [], on: viewCotnroller)
    }
    
    public static func present(_ message: String?, cancel: String, other: [(String, (()->())?)], on viewController: UIViewController) -> UIAlertController {
        return present(message, cancel: (cancel, nil), other: other, on: viewController)
    }
    
    public static func present(_ message: String?, cancel: (String, (()->())?), other: [(String, (()->())?)], on viewController: UIViewController) -> UIAlertController {
        return present(title: defaultTitle, message: message, cancel: cancel, other: other, on: viewController)
    }
    
    public static func present(title: String?, message: String?, cancel: (String, (()->())?), other: [(String, (()->())?)], on viewController: UIViewController) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
        })
        for action in other {
            alert.addAction(UIAlertAction(title: action.0, style: .default, handler: { (_) in
                action.1?()
            }))
        }
        viewController.present(alert, animated: true, completion: nil)
        return alert
    }
}

public extension AMAlert {
    
    fileprivate static var associatedActions: [UITextField : UIAlertAction] = [:]
    
    public static func present(_ message: String?, cancel: (String, (()->())?), other: [(String, (([UITextField])->())?)], fieldsSetup: [(UITextField)->()], on viewController: UIViewController) -> UIAlertController {
        return present(title: defaultTitle, message: message, cancel: cancel, other: other, fieldsSetup: fieldsSetup, on: viewController)
    }
    
    public static func present(title: String?, message: String?, cancel: (String, (()->())?), other: [(String, (([UITextField])->())?)], fieldsSetup: [(UITextField)->()], on viewController: UIViewController) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        var lastAction: UIAlertAction?
        var fields: [UITextField] = []
        for setubBlock in fieldsSetup {
            alert.addTextField(configurationHandler: { (textfield) in
                textfield.clearButtonMode = .whileEditing
                setubBlock(textfield)
                textfield.addTarget(shared, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                fields.append(textfield)
            })
        }
        
        alert.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
            clear(fields: fields)
        })
        for action in other {
            alert.addAction(UIAlertAction(title: action.0, style: .default, handler: { (_) in
                action.1?(fields)
                clear(fields: fields)
            }))
            lastAction = alert.actions.last
        }
        viewController.present(alert, animated: true, completion: nil)
        
        if let action = lastAction {
            for field in fields {
                associatedActions[field] = action
            }
        }
        return alert
    }
    
    private static func clear(fields: [UITextField]) {
        for field in fields {
            associatedActions[field] = nil
        }
    }
    
    @objc private func textFieldDidChange(_ field: UITextField) {
        type(of: self).associatedActions[field]?.isEnabled = field.text?.count ?? 0 > 0
    }
}

public extension AMAlert {
    public static func presentSheet(title: String?, message: String?, cancel: (String, (()->())?), other: [(String, (()->())?)], destructive: Int?, on view: UIView, inRect: CGRect) -> UIAlertController {
        return presentSheet(title: title, message: message, cancel: cancel, other: other, destructive: destructive, item: view, inRect: inRect, on: nil)
    }
    
    public static func presentSheet(title: String?, message: String?, cancel: (String, (()->())?), other: [(String, (()->())?)], destructive: Int?, barButton: UIBarButtonItem, on viewController: UIViewController) -> UIAlertController {
        return presentSheet(title: title, message: message, cancel: cancel, other: other, destructive: destructive, item: barButton, inRect: CGRect.zero, on: viewController)
    }
    
    fileprivate static func presentSheet(title: String?, message: String?, cancel: (String, (()->())?), other: [(String, (()->())?)], destructive: Int?, item: Any, inRect: CGRect, on viewController: UIViewController?) -> UIAlertController {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
        })
        for (index, action) in other.enumerated() {
            sheet.addAction(UIAlertAction(title: action.0, style: index == destructive ? .destructive : .default, handler: { (_) in
                action.1?()
            }))
        }
        
        var vc = viewController
        if let item = item as? UIBarButtonItem {
            sheet.popoverPresentationController?.barButtonItem = item
        } else if let item = item as? UIView {
            sheet.popoverPresentationController?.sourceRect = inRect
            sheet.popoverPresentationController?.sourceView = item
            
            var responder: UIResponder? = item.next
            while responder != nil && responder as? UIViewController == nil {
                responder = responder!.next
            }
            vc = responder as? UIViewController
        }
        vc!.present(sheet, animated: true, completion: nil)
        return sheet
    }
}

// ObjectiveC Bridge
@objc public extension AMAlert {
    
    // as Any should be block ()->()
    @available(swift, obsoleted: 1.0)
    public static func present(_ message: String?, cancel: [String:Any], other: [[String:Any]], on viewController: UIViewController) -> UIAlertController {
        return present(title: defaultTitle, message: message, cancel: cancel, other: other, on: viewController)
    }
    
    // as Any should be block ()->()
    public static func present(title: String?, message: String?, cancel: [String:Any], other: [[String:Any]], on viewController: UIViewController) -> UIAlertController {
        let others: [(String, (()->())?)] = other.map { (other) in
            return (other.keys.first!, other[other.keys.first!] as? ()->())
        }
        return present(message, cancel: (cancel.keys.first!, cancel[cancel.keys.first!] as? ()->()), other: others, on: viewController)
    }
    
    // as Any should be block (UITextField)->()
    @available(swift, obsoleted: 1.0)
    public static func present(_ message: String?, cancel: [String:Any], other: [[String:Any]], fieldsSetup: [Any], on viewController: UIViewController) -> UIAlertController {
        return present(title: defaultTitle, message: message, cancel: cancel, other: other, fieldsSetup: fieldsSetup, on: viewController)
    }
    
    // in other should be block ([UITextField])->(), fieldSetup (UITextField)->()
    public static func present(title: String?, message: String?, cancel: [String:Any], other: [[String:Any]], fieldsSetup: [Any], on viewController: UIViewController) -> UIAlertController {
        let others: [(String, (([UITextField])->())?)] = other.map { (other) in
            return (other.keys.first!, other[other.keys.first!] as? ([UITextField])->())
        }
        let fields: [(UITextField)->()] = fieldsSetup.map { (field) in
            return field as! (UITextField)->()
        }
        return present(title: title, message: message, cancel: (cancel.keys.first!, cancel[cancel.keys.first!] as? ()->()), other: others, fieldsSetup: fields, on: viewController)
    }
    
    @available(swift, obsoleted: 1.0)
    public static func presentSheet(title: String, message: String, cancel: [String:Any], other: [[String:Any]], destructive: Int, on view: UIView, inRect: CGRect) -> UIAlertController {
        let others: [(String, (()->())?)] = other.map { (other) in
            return (other.keys.first!, other[other.keys.first!] as? ()->())
        }
        return presentSheet(title: title, message: message, cancel: (cancel.keys.first!, cancel[cancel.keys.first!] as? ()->()), other: others, destructive: destructive, item: view, inRect: inRect, on: nil)
    }
    
    @available(swift, obsoleted: 1.0)
    public static func presentSheet(title: String, message: String, cancel: [String:Any], other: [[String:Any]], destructive: Int, barButton: UIBarButtonItem, on viewController: UIViewController) -> UIAlertController {
        let others: [(String, (()->())?)] = other.map { (other) in
            return (other.keys.first!, other[other.keys.first!] as? ()->())
        }
        return presentSheet(title: title, message: message, cancel: (cancel.keys.first!, cancel[cancel.keys.first!] as? ()->()), other: others, destructive: destructive, item: barButton, inRect: CGRect.zero, on: viewController)
    }
}