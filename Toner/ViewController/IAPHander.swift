//
//  IAPHander.swift
//  Toner
//
//  Created by Shalu Tyagi on 20/01/22.
//  Copyright © 2022 Users. All rights reserved.
//


import UIKit
import StoreKit

enum Product: String, CaseIterable {
    case one_month_subscription = "com.release.tonneru.one.month"
    case one_year_subscription = "com.release.tonneru.one.year"
}

enum IAPHandlerAlertType {
    case setProductIds
    case disabled
    case restored
    case purchased
    case failed
    
    var message: String{
        switch self {
        case .setProductIds: return "Product ids not set, call setProductIds method!"
        case .disabled: return "Purchases are disabled in your device!"
        case .restored: return "You've successfully restored your purchase!"
        case .purchased: return "You've successfully bought this purchase!"
        case .failed: return "Purchase is failed!"
        }
    }
}

class IAPHander: NSObject {
    
    //MARK:- Shared Object
    //MARK:-
    static let shared = IAPHander()
    private override init() { }
    
    //MARK:- Properties
    //MARK:- Private
    fileprivate var productIds = [String]()
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var productToPurchase: SKProduct?
    
    var purchaseProductComplition: ((IAPHandlerAlertType, SKProduct?, SKPaymentTransaction?)->Void)?
    var fetchProductComplition: (([SKProduct])->Void)?
    
    //MARK:- Public
    var isLogEnabled: Bool = true
    
    //MARK:- Methods
    //MARK:- Public
    
    //Set Product Ids
    func setProductIds() {
        self.productIds = Product.allCases.compactMap({ $0 .rawValue })
    }
    
    //MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    func purchase(product: SKProduct, complition: @escaping ((IAPHandlerAlertType, SKProduct?, SKPaymentTransaction?)->Void)) {
        
        self.purchaseProductComplition = complition
        self.productToPurchase = product
        
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            log("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            productID = product.productIdentifier
        }
        else {
            complition(IAPHandlerAlertType.disabled, nil, nil)
        }
    }
    
    // RESTORE PURCHASE
    func restorePurchase(){
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    
    // FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts(complition: @escaping (([SKProduct])->Void)){
        
        self.setProductIds()
        
        self.fetchProductComplition = complition
        // Put here your IAP Products ID's
        if self.productIds.isEmpty {
            log(IAPHandlerAlertType.setProductIds.message)
            fatalError(IAPHandlerAlertType.setProductIds.message)
        }
        else {
            productsRequest = SKProductsRequest(productIdentifiers: Set(self.productIds))
            productsRequest.delegate = self
            productsRequest.start()
        }
    }
    
    //MARK:- Private
    fileprivate func log <T> (_ object: T) {
        if isLogEnabled {
            NSLog("\(object)")
        }
    }
}

//MARK:- Product Request Delegate and Payment Transaction Methods
//MARK:-
extension IAPHander: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    // REQUEST IAP PRODUCTS
    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        
        if (response.products.count > 0) {
            if let complition = self.fetchProductComplition {
                complition(response.products)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if let complition = self.purchaseProductComplition {
            complition(IAPHandlerAlertType.restored, nil, nil)
        }
    }
    
    // IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    log("Product purchase done")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    if let complition = self.purchaseProductComplition {
                        complition(IAPHandlerAlertType.purchased, self.productToPurchase, trans)
                    }
                    break
                    
                case .failed:
                    log("Product purchase failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    if let complition = self.purchaseProductComplition {
                        complition(IAPHandlerAlertType.failed, self.productToPurchase, trans)
                    }
                    break
                case .restored:
                    log("Product restored")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    if let complition = self.purchaseProductComplition {
                        complition(IAPHandlerAlertType.restored, self.productToPurchase, trans)
                    }
                    break
                    
                default: break
                }}}
    }
}

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}
