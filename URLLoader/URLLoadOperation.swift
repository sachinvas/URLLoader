//
//  URLLoadOperation.swift
//  URLLoader
//
//  Created by Sachin Vas on 11/05/17.
//  Copyright © 2017 Sachin Vas. All rights reserved.
//

import Foundation


class URLLoadOperation: Operation {
    
    var loadURLString: String
    var loads: [URLLoad?]?
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        if _finished {
            loads?.removeAll()
        }
        return _finished
    }
    
    init(_ urlString: String) {
        loadURLString = urlString
        loads = [URLLoad?]()
    }
    
    func addLoad(_ load: URLLoad) {
        loads?.append(load)
    }
    
    func removeLoad(_ load: URLLoad) {
        if let existingIndex = loads?.index(where: {$0 === load}) {
            loads?.remove(at: existingIndex)
        }
        if let existingLoads = loads, existingLoads.count == 0  {
            cancel()
        }
    }
    
    override func start() {
        if self.isCancelled {
            _finished = true
        } else {
            _executing = true
            main()
        }
    }
    
    override func main() {
        let url = URL(string: self.loadURLString)!
        NetworkManager.shared.downloadContentOfURL(url) {[weak self] (result) in
            var success = false
            var error: Error? = nil
            var entry: (Data, String)? = nil
            switch result {
            case .failure(let networkError):
                error = networkError
            case .success(let networkData, let httpResponse):
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 209, let dataType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    success = true
                    entry = (networkData, dataType)
                }
            }
            if let weakSelf = self, let weakLoads = weakSelf.loads {
                for load in weakLoads {
                    load?.complete(success, entry: entry, error: error)
                }
            }
            self?._finished = true
        }
    }
}
