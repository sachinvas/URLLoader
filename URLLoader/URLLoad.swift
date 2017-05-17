//
//  URLLoaderQueue.swift
//  Pods
//
//  Created by Sachin Vas on 12/05/17.
//
//

import Foundation

protocol URLLoadProtocol: class {
    func load(_ load: URLLoad, didCancelLoading cancelled: Bool)
    func load(_ load: URLLoad, didComplete complete: (Bool, (Data, String)?, Error?))
}

class URLLoad: URLLoaderProtocol {
    var urlOperation: URLLoadOperation
    weak var delegate: URLLoadProtocol?
    var completionBlock: URLLoadCompletion?
        
    init(_ op: URLLoadOperation, completionBlock cb: URLLoadCompletion?) {
        urlOperation = op
        completionBlock = cb
    }
    
    func complete(_ success: Bool, entry: (Data, String)?, error: Error?) {
        delegate?.load(self, didComplete: (success, entry, error))
    }
    
    func cancel() {
        urlOperation.removeLoad(self)
        completionBlock = nil
        if delegate != nil {
            delegate?.load(self, didCancelLoading: true)
        }
    }
}
