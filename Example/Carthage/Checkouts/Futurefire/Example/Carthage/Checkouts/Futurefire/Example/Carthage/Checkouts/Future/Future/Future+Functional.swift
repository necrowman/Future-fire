//===--- Future+Functional.swift ------------------------------------------------------===//
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

public extension Future {
    public func onComplete(callback: Result<Value, AnyError> -> Void) -> Self {
        return self.onCompleteInternal(callback)
    }
}

public extension FutureType {
    public func onSuccess(f: Value -> Void) -> Self {
        return self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                f(value)
            }, ifFailure: {_ in})
        }
    }
    
    public func onFailure<E : ErrorProtocol>(f: E -> Void) -> Self{
        return self.onComplete { (result:Result<Value, E>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error)
            })
        }
    }
    
    public func onFailure(f: ErrorProtocol -> Void) -> Self {
        return self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error.error)
            })
        }
    }
}

public extension FutureType {
    public func map<B>(f:(Value) throws -> B) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            let result = result.flatMap { value in
                materializeAny {
                    try f(value)
                }
            }
            try! future.complete(result)
        }
        
        return future
    }
    
    public func flatMap<B, F : FutureType where F.Value == B>(f:(Value) -> F) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                b.onComplete { (result:Result<B, AnyError>) in
                    try! future.complete(result)
                }
            }, ifFailure: { error in
                try! future.fail(error)
            })
        }
        
        return future
    }
    
    public func flatMap<B, E : ErrorProtocol>(f:(Value) -> Result<B, E>) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                try! future.complete(b)
            }, ifFailure: { error in
                try! future.fail(error)
            })
        }
        
        return future
    }
    
    public func flatMap<B>(f:(Value) -> B?) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            let result:Result<B, AnyError> = result.flatMap { value in
                guard let b = f(value) else {
                    return Result(error: AnyError(Error.MappedNil))
                }
                return Result(value: b)
            }
            try! future.complete(result)
        }
        
        return future
    }
    
    public func filter(f: (Value)->Bool) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                if f(value) {
                    try! future.success(value)
                } else {
                    try! future.fail(Error.FilteredOut)
                }
                }, ifFailure: { error in
                    try! future.fail(error)
            })
        }
        
        return future
    }
    
    public func filterNot(f: (Value)->Bool) -> Future<Value> {
        return self.filter { value in
            return !f(value)
        }
    }
    
    public func recover<E : ErrorProtocol>(f:(E) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        self.onComplete { (result:Result<Value, E>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error)
                }
            }
            future.tryComplete(result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(self)
        
        return future
    }
    
    public func recover(f:(ErrorProtocol) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error.error)
                }
            }
            future.tryComplete(result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(self)
        
        return future
    }
    
    public func recoverWith<E : ErrorProtocol>(f:(E) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, E> = result.tryAsError() else {
                try! future.complete(result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ in
                try! future.complete(result)
            }, ifFailure: { e in
                future.completeWith(f(e))
            })
        }
        
        return future
    }
    
    public func recoverWith(f:(ErrorProtocol) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, AnyError> = result.tryAsError() else {
                try! future.complete(result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ in
                try! future.complete(result)
            }, ifFailure: { e in
                future.completeWith(f(e.error))
            })
        }
        
        return future
    }
    
    public func zip<B, F : FutureType where F.Value == B>(f:F) -> Future<(Value, B)> {
        let future = MutableFuture<(Value, B)>(context: self.context)
        
        self.onComplete { (result:Result<Value, AnyError>) in
            let context = ExecutionContext.current
            
            result.analysis(ifSuccess: { first -> Void in
                f.onComplete { (result:Result<B, AnyError>) in
                    context.execute {
                        result.analysis(ifSuccess: { second in
                            try! future.success((first, second))
                        }, ifFailure: { e in
                            try! future.fail(e.error)
                        })
                    }
                }
                
            }, ifFailure: { e in
                try! future.fail(e.error)
            })
        }
        
        return future
    }
}