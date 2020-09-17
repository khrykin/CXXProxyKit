//
//  CXXProxyArray+Sequence.swift
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 17.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

import Foundation

public struct CXXProxyListIterator<T>: IteratorProtocol {
    var fastEnumerator: NSFastEnumerationIterator

    public init(_ enumerable: NSFastEnumeration) {
        fastEnumerator = NSFastEnumerationIterator(enumerable)
    }

    public mutating func next() -> T? {
        return fastEnumerator.next() as? T;
    }

    public typealias Element = T
}

public protocol CXXProxyListSequence: NSFastEnumeration, Sequence {
    associatedtype Element
}

extension CXXProxyListSequence  {
    public func makeIterator() -> ProxyListIterator<Element> {
        return ProxyListIterator<Element>(self)
    }
}
