//
//  RxUtils.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension ObservableType {
    func waitUntil<O: ObservableType>(other: O) -> Observable<Self.E> {
        return other.take(1).flatMap {_ in Observable.empty()}.concat(self)
    }
    
    func empty<T>() -> Observable<T> {
        return flatMap {_ in Observable<T>.empty()}
    }
}

struct RxUtil {
    private init() {}
    
    @warn_unused_result(message="http://git.io/rxs.ud")
    static func bind<E: Equatable>(lhs: Variable<E>, _ rhs: Variable<E>) -> Disposable {
        return CompositeDisposable(
            lhs.asObservable().filter {[weak rhs] in (rhs?.value != $0) ?? false}.bindTo(rhs),
            rhs.asObservable().filter {[weak lhs] in (lhs?.value != $0) ?? false}.bindTo(lhs)
        )
    }
    
    @warn_unused_result(message="http://git.io/rxs.ud")
    static func bind<E1: Equatable, E2: Equatable>(lhs: Variable<E1>, _ rhs: Variable<E2>, binder1: E1 -> E2, binder2: E2 -> E1) -> Disposable {
        return CompositeDisposable(
            lhs.asObservable().map(binder1).filter {[weak rhs] in (rhs?.value != $0) ?? false}.bindTo(rhs),
            rhs.asObservable().map(binder2).filter {[weak lhs] in (lhs?.value != $0) ?? false}.bindTo(lhs)
        )
    }
    
    @warn_unused_result(message="http://git.io/rxs.ud")
    static func bind<E: Equatable>(lhs: Variable<E>, _ rhs: ControlProperty<E>) -> Disposable {
        return CompositeDisposable(lhs.asObservable().bindTo(rhs), rhs.bindTo(lhs))
    }
    
    @warn_unused_result(message="http://git.io/rxs.ud")
    static func bind<E: Equatable>(lhs: ControlProperty<E>, _ rhs: Variable<E>) -> Disposable {
        return bind(rhs, lhs)
    }
    
    @warn_unused_result(message="http://git.io/rxs.ud")
    static func bind<E: Equatable>(lhs: ControlProperty<E>, _ rhs: ControlProperty<E>) -> Disposable {
        return CompositeDisposable(lhs.bindTo(rhs), rhs.bindTo(lhs))
    }
}