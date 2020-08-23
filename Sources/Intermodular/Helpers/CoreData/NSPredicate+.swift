//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

public protocol TypedPredicateProtocol: NSPredicate {
    associatedtype Root
}

public final class CompoundPredicate<Root>: NSCompoundPredicate, TypedPredicateProtocol {
    
}

public final class ComparisonPredicate<Root>: NSComparisonPredicate, TypedPredicateProtocol {
    
}

public func && <TP1: TypedPredicateProtocol, TP2: TypedPredicateProtocol>(p1: TP1, p2: TP2) -> CompoundPredicate<TP1.Root> where TP1.Root == TP2.Root {
    CompoundPredicate(type: .and, subpredicates: [p1, p2])
}

public func || <TP1: TypedPredicateProtocol, TP2: TypedPredicateProtocol>(p1: TP1, p2: TP2) -> CompoundPredicate<TP1.Root> where TP1.Root == TP2.Root {
    CompoundPredicate(type: .or, subpredicates: [p1, p2])
}

public prefix func ! <TP: TypedPredicateProtocol>(p: TP) -> CompoundPredicate<TP.Root> {
    CompoundPredicate(type: .not, subpredicates: [p])
}

// MARK: - comparison operators
public func == <E: Equatable, R, K: KeyPath<R, E>>(kp: K, value: E) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .equalTo, value)
}

public func != <E: Equatable, R, K: KeyPath<R, E>>(kp: K, value: E) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .notEqualTo, value)
}

public func > <C: Comparable, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .greaterThan, value)
}

public func < <C: Comparable, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .lessThan, value)
}

public func <= <C: Comparable, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .lessThanOrEqualTo, value)
}

public func >= <C: Comparable, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .greaterThanOrEqualTo, value)
}

public func === <S: Sequence, R, K: KeyPath<R, S.Element>>(kp: K, values: S) -> ComparisonPredicate<R> where S.Element: Equatable {
    ComparisonPredicate(kp, .in, values)
}

extension ComparisonPredicate {
    convenience init<VAL>(_ kp: KeyPath<Root, VAL>, _ op: NSComparisonPredicate.Operator, _ value: Any?) {
        let ex1 = \Root.self == kp ? NSExpression.expressionForEvaluatedObject() : NSExpression(forKeyPath: kp)
        let ex2 = NSExpression(forConstantValue: value)
        self.init(leftExpression: ex1, rightExpression: ex2, modifier: .direct, type: op)
    }
}
