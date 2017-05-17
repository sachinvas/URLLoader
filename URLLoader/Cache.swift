//
//  Cache.swift
//  URLLoader
//
//  Created by Sachin Vas on 11/05/17.
//  Copyright © 2017 Sachin Vas. All rights reserved.
//

import Foundation

//protocol CacheDelegate: class {
//    func cache(_ cache: Cache, shouldEvictObject object: AnyObject) -> Bool
//    func cache(_ cache: Cache, willEvictObject object: AnyObject)
//}

typealias Entry = (object: Data, type: DataType)

class CacheEntry {
    var entry: Entry
    var cost: Int
    var sequenceNumber: Int
    
    init(_ entry: Entry, cost: Int, sequenceNumber: Int) {
        self.entry = entry
        self.cost = cost
        self.sequenceNumber = sequenceNumber
    }
}

class Cache {
    
    var name: String
    var cacheEntries = [String: CacheEntry]()
    var sequenceNumber = 0
    var costOfCacheEntries = 0
    var lock: NSRecursiveLock
    
    var totalCostLimit: Int
    var totalCountLimit: Int
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    init(_ name: String, totalCostLimit: Int, totalCountLimit: Int) {
        self.name = name
        self.totalCostLimit = totalCostLimit
        self.totalCountLimit = totalCountLimit
        lock = NSRecursiveLock()
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeAllObjects(_:)), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    func cleanCache() {
        lock.lock()
        let maxCount = self.totalCountLimit
        let maxCost = self.totalCostLimit
        var totalCount = cacheEntries.count;
        while totalCount > maxCount || costOfCacheEntries > maxCost {
            
            let lowestKey = cacheEntries.min(by: { (entry1, entry2) -> Bool in
                return entry1.value.sequenceNumber < entry2.value.sequenceNumber
            })
            
            if let key = lowestKey?.key {
                if let entry = cacheEntries.removeValue(forKey: key) {
                    costOfCacheEntries -= entry.cost
                }
                totalCount -= 1
            }
        }
        lock.unlock()
    }
    
    func resequnce() {
        
        let cacheEntries = Array(self.cacheEntries.values).sorted { (cacheEntry1, cacheEntry2) -> Bool in
             return (ComparisonResult(rawValue: min(1, max(-1, cacheEntry1.sequenceNumber - cacheEntry2.sequenceNumber)))!).rawValue % 2 == 0
        }
        
        var index = 0
        for cacheEntry in cacheEntries {
            cacheEntry.sequenceNumber = index
            index += 1
        }
    }
    
    func setObject(_ entry: Entry, forKey key: String, cost: Int) {
        lock.lock()
        cleanCache()
        if let availableEntry = cacheEntries[key] {
            costOfCacheEntries -= availableEntry.cost
            availableEntry.cost = cost
            availableEntry.entry = entry
            availableEntry.sequenceNumber = sequenceNumber
            sequenceNumber += 1
        } else {
            let entry = CacheEntry(entry, cost: cost, sequenceNumber: sequenceNumber)
            sequenceNumber += 1
            cacheEntries[key] = entry
        }
        if sequenceNumber < 0 {
            resequnce()
        }
        costOfCacheEntries += cost
        lock.unlock()
    }
    
    func removeObject(forKey key: String) {
        lock.lock()
        if let entry = cacheEntries.removeValue(forKey: key) {
            costOfCacheEntries -= entry.cost
        }
        lock.unlock()
    }
    
    @objc func removeAllObjects(_ notification: Notification? = nil) {
        lock.lock()
        costOfCacheEntries = 0
        cacheEntries.removeAll()
        lock.unlock()
    }
    
    
    subscript(_ key: String) -> AnyObject? {
        lock.lock()
        var object: AnyObject?
        if let cacheEntry = cacheEntries[key] {
            cacheEntry.sequenceNumber += sequenceNumber
            sequenceNumber += 1
            if sequenceNumber < 0 {
                self.resequnce()
            }
            switch cacheEntry.entry.type {
            case .jpeg:
                object = UIImage(data: cacheEntry.entry.object)
            case .plain:
                fallthrough
            case .json:
                object = cacheEntry.entry.object as AnyObject
            }
        } else {
            object = nil
        }
        lock.unlock()
        return object
    }
}
