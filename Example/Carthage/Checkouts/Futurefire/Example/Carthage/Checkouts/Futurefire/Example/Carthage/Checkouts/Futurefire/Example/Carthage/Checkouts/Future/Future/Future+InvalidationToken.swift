//===--- Future+InvalidationToken.swift ------------------------------------------------------===//
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

import Result
import Boilerplate

public extension Future {
    public func onComplete(token:InvalidationToken, callback: Result<Value, AnyError> -> Void) -> Self {
        return self.onComplete(token.closure(callback))
    }
}

public extension FutureType {
    public func onComplete<E: ErrorProtocol>(token:InvalidationToken, callback: Result<Value, E> -> Void) -> Self {
        return self.onComplete(token.closure(callback))
    }
    
    public func onSuccess(token:InvalidationToken, f: Value -> Void) -> Self {
        return self.onSuccess(token.closure(f))
    }
    
    public func onFailure<E : ErrorProtocol>(token:InvalidationToken, f: E -> Void) -> Self{
        return self.onFailure(token.closure(f))
    }
    
    public func onFailure(token:InvalidationToken, f: ErrorProtocol -> Void) -> Self {
        return self.onFailure(token.closure(f))
    }
}
