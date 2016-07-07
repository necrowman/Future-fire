//===--- Future.swift ------------------------------------------------------===//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===----------------------------------------------------------------------===//

import Foundation
import Result
import Boilerplate
import ExecutionContext

public protocol FutureType : ExecutionContextTenantProtocol {
    associatedtype Value
    
    init(value:Value)
    init(error:ErrorProtocol)
    init<E : ErrorProtocol>(result:Result<Value, E>)
    
    func onComplete<E: ErrorProtocol>(callback: Result<Value, E> -> Void) -> Self
    
    var isCompleted:Bool {get}
}

public class Future<V> : FutureType {
    public typealias Value = V
    
    private var _chain:TaskChain?
    private var _resolver:ExecutionContextType?
    internal var result:Result<Value, AnyError>? = nil {
        didSet {
            if result != nil {
                self.isCompleted = true
                
                /// some performance optimization is done here, so don't touch the ifs. ExecutionContext.current is not the fastest func
                let context = selectContext()
                
                _chain!.append { next in
                    return { context in
                        admin.execute {
                            self._resolver = context
                            self._chain = nil
                            context.execute {
                                next.content?(context)
                            }
                        }
                    }
                }
                
                _chain!.perform(context)
            }
        }
    }
    
    public let context: ExecutionContextType
    //make it atomic later
    private (set) public var isCompleted:Bool = false
    
    internal init(context:ExecutionContextType) {
        self._chain = TaskChain()
        self.context = context
    }
    
    public required convenience init(value:Value) {
        self.init(result: Result<Value, AnyError>(value: value))
    }
    
    public required convenience init(error:ErrorProtocol) {
        self.init(result: Result(error: AnyError(error)))
    }
    
    public required convenience init<E : ErrorProtocol>(result:Result<Value, E>) {
        self.init(context: immediate)
        self.result = result.asAnyError()
        self.isCompleted = true
        self._resolver = selectContext()
        self._chain = nil
    }
    
    private func selectContext() -> ExecutionContextType {
        return self.context.isEqualTo(immediate) ? ExecutionContext.current : self.context
    }
    
    public func onComplete<E: ErrorProtocol>(callback: Result<Value, E> -> Void) -> Self {
        return self.onCompleteInternal(callback)
    }
    
    //to avoid endless recursion
    internal func onCompleteInternal<E: ErrorProtocol>(callback: Result<Value, E> -> Void) -> Self {
        admin.execute {
            if let resolver = self._resolver {
                let mapped:Result<Value, E>? = self.result!.tryAsError()
                if let result = mapped {
                    resolver.execute {
                        callback(result)
                    }
                }
            } else {
                self._chain!.append { next in
                    return { context in
                        let mapped:Result<Value, E>? = self.result!.tryAsError()
                        
                        if let result = mapped {
                            callback(result)
                            next.content?(context)
                        } else {
                            next.content?(context)
                        }
                    }
                }
            }
        }
        
        return self
    }
}

extension Future : MovableExecutionContextTenantProtocol {
    public typealias SettledTenant = Future<Value>
    
    public func settle(in context: ExecutionContextType) -> SettledTenant {
        let future = MutableFuture<Value>(context: context)
        
        future.completeWith(self)
        
        return future
    }
}

public func future<T>(context:ExecutionContextType = contextSelector(), task:() throws ->T) -> Future<T> {
    let future = MutableFuture<T>(context: context)
    
    context.execute {
        do {
            let value = try task()
            try! future.success(value)
        } catch let e {
            try! future.fail(e)
        }
    }
    
    return future
}

public func future<T, E : ErrorProtocol>(context:ExecutionContextType = contextSelector(), task:() -> Result<T, E>) -> Future<T> {
    let future = MutableFuture<T>(context: context)
    
    context.execute {
        let result = task()
        try! future.complete(result)
    }
    
    return future
}

public func future<T, F : FutureType where F.Value == T>(context:ExecutionContextType = contextSelector(), task:() -> F) -> Future<T> {
    let future = MutableFuture<T>(context: context)
    
    context.execute {
        future.completeWith(task())
    }
    
    return future
}
