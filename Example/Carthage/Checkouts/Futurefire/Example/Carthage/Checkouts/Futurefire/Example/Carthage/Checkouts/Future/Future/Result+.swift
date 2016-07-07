//===--- Result+.swift ------------------------------------------------------===//
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

internal extension Result {
    func tryMapError<E : ErrorProtocol>(f:(Error)->E?) -> Result<T, E>? {
        guard let error = self.error else {
            return self.mapError { e in
                //will never be called
                f(e)!
            }
        }
        
        guard let mapped = f(error) else {
            return nil
        }
        
        return Result<T, E>(error: mapped)
    }
    
    func asAnyError() -> Result<T, AnyError> {
        return self.mapError { error in
            return anyError(error)
        }
    }
}

internal extension Result where Error : AnyErrorProtocol {
    func tryAsError<E : ErrorProtocol>() -> Result<T, E>? {
        return self.tryMapError { e -> E? in
            if let e = asNoBridge(e.error, type:NSError.self).flatMap({$0 as? E}) {
                return e
            } else {
                switch e {
                case let e as E:
                    return e
                default:
                    return e.error as? E
                }
            }
        }
    }
}