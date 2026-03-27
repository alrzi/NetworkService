//
//  RetryInterceptor.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Интерцептор для обработки повторных попыток
struct RetryInterceptor: RequestInterceptor {
    private let maxRetries: Int
    private let baseDelay: Duration
    private let clock: any Clock<Duration>

    init(
        maxRetries: Int,
        baseDelay: Duration = .seconds(1),
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.clock = clock
    }

    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest {
        request
    }

    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision {
        // Проверяем, можно ли повторить запрос
        guard error.isRetryable else {
            return .doNotRetry
        }

        // Проверяем лимит попыток
        guard attempt < maxRetries else {
            return .doNotRetry
        }

        // Вычисляем задержку с экспоненциальным backoff
        let delay = baseDelay * pow(2.0, Double(attempt))

        // Добавляем jitter (±25%)
        let delaySeconds = Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18
        let jitterRange = delaySeconds * 0.25
        let jitter = Double.random(in: -jitterRange...jitterRange)
        let finalDelay = Duration.seconds(delaySeconds + jitter)

        do {
            try await clock.sleep(for: finalDelay)
            return .retry
        }
        catch {
            // Задача была отменена во время ожидания
            return .doNotRetry
        }
    }
}
