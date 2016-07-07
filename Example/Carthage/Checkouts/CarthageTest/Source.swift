//
//  Source.swift
//  CarthageTest
//
//  Created by Ruslan Yupyn on 7/6/16.
//
//

import Foundation
import Alamofire
import Future

public extension Alamofire.Request {
    public func responseJSON() -> Future<AnyObject> {
        
        let p = Promise<AnyObject>()
        self.responseJSON { (response: Response<AnyObject, NSError>) in
            switch response.result {
            case .Success(let value):
                p.trySuccess(value)
            case .Failure(let error):
                p.tryFail(error)
            }
        }
        return p.future
    }
    
    public func response() -> Future<NSData?> {
        let p = Promise<NSData?>()
        self.response { (request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) in
            if let error = error {
                p.tryFail(error)
            } else {
                p.trySuccess(data)
            }
        }
        return p.future
    }
    
    public func responseData() -> Future<NSData> {
        let p = Promise<NSData>()
        self.responseData { (response: Response<NSData, NSError>) in
            switch response.result {
            case .Success(let value):
                p.trySuccess(value)
            case .Failure(let error):
                p.tryFail(error)
            }
        }
        return p.future
    }
    
    public func responseString() -> Future<String> {
        let p = Promise<String>()
        self.responseString { (response: Response<String, NSError>) in
            switch response.result {
            case .Success(let value):
                p.trySuccess(value)
            case .Failure(let error):
                p.tryFail(error)
            }
        }
        return p.future
    }
    
    public func responsePropertyList() -> Future<AnyObject> {
        let p = Promise<AnyObject>()
        self.responsePropertyList { (response: Response<AnyObject, NSError>) in
            //            try! p.complete(response.result)
            switch response.result {
            case .Success(let value):
                print("RESULT class:", value.classForCoder)
                p.trySuccess(value)
            case .Failure(let error):
                p.tryFail(error)
            }
        }
        return p.future
    }
}

public class Source {
    
    public func abc() -> Int {
        return 123
    }
    
}
