//
//  UserSession.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 25.03.2026.
//

import AsyncExtensions
import Foundation
import NetworkServiceDomain

/// Контекст идентификации пользователя
public final class UserSession: UserSessionProtocol {
    private let storage: any TokenStorageProtocol

    private let statusStream: CurrentValueAsyncSequence<SessionStatus>
    public var status: CurrentValueAsyncSequenceReadOnly<SessionStatus> { statusStream.readOnly() }

    public var currentStatus: SessionStatus {
        get async { await statusStream.value }
    }

    public init(storage: any TokenStorageProtocol) {
        self.storage = storage
        self.statusStream = .init(storage.loadToken() != nil ? .authenticated : .unauthenticated)
    }

    public func setSession(token: AuthToken) async {
        storage.saveToken(token)

        await statusStream.setValue(.authenticated)
    }

    public func logout() async {
        storage.clearAll()

        await statusStream.setValue(.unauthenticated)
    }
}

extension UserSession: SessionCredentialsProvider {
    public func getValidToken() -> AuthToken? {
        storage.loadToken()
    }

    public func updateToken(_ newToken: AuthToken) {
        storage.saveToken(newToken)
    }

    public func notifyInvalidToken() async {
        storage.clearAll()

        await statusStream.setValue(.unauthenticated)
    }
}
