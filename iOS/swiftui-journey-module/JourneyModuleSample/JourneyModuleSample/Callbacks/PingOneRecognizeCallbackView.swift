//
//  PingOneRecognizeCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourneyPlugin
import KeylessSDK
import Combine

extension AbstractCallback {
    var prettyJSON: String {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

public class PingOneRecognizeCallback: AbstractCallback, @unchecked Sendable {
    // Stable identifier so SwiftUI preserves KeylessView identity across re-renders.
    // AbstractCallback.id returns a new UUID on every access, so we store our own.
    public let stableId: String = UUID().uuidString

    nonisolated(unsafe) private(set) public var apiKey: String = ""
    nonisolated(unsafe) private(set) public var host: String = ""
    nonisolated(unsafe) private(set) public var operationType: String = ""
    nonisolated(unsafe) private(set) public var clientState: String = ""
    nonisolated(unsafe) private(set) public var username: String = ""
    nonisolated(unsafe) private(set) public var transactionData: String = ""
    nonisolated(unsafe) private(set) public var generateClientState: Bool = false
    nonisolated(unsafe) private(set) public var mobileSDKOptions: [String: String] = [:]

    nonisolated required public init() {
        super.init()
    }

    nonisolated public override func initValue(name: String, value: Any) {
        switch name {
        case "apiKey":
            if let stringValue = value as? String { self.apiKey = stringValue }
        case "host":
            if let stringValue = value as? String { self.host = stringValue }
        case "operationType":
            if let stringValue = value as? String { self.operationType = stringValue }
        case "clientState":
            if let stringValue = value as? String { self.clientState = stringValue }
        case "username":
            if let stringValue = value as? String { self.username = stringValue }
        case "transactionData":
            if let stringValue = value as? String { self.transactionData = stringValue }
        case "generateClientState":
            if let boolValue = value as? Bool { self.generateClientState = boolValue }
        case "mobileSDKOptions":
            if let dict = value as? [String: String] {
                self.mobileSDKOptions = dict
            } else if let dict = value as? [String: Any] {
                self.mobileSDKOptions = dict.compactMapValues { $0 as? String }
            }
        default:
            break
        }
    }

    public func setSignedJwt(_ value: String) {
        _ = input(value, forKey: "IDToken1signedJwt")
    }

    public func setInputClientState(_ value: String) {
        _ = input(value, forKey: "IDToken1clientState")
    }

    public func setRecognizeId(_ value: String) {
        _ = input(value, forKey: "IDToken1recognizeId")
    }

    public func setClientError(_ value: String) {
        _ = input(value, forKey: "IDToken1clientError")
    }

    public func setClientErrorCode(_ value: String) {
        _ = input(value, forKey: "IDToken1clientErrorCode")
    }
}

struct PingOneRecognizeCallbackView: View {
    @StateObject private var viewModel: PingOneRecognizeViewModel

    init(callback: PingOneRecognizeCallback, onNext: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: PingOneRecognizeViewModel(callback: callback, onNext: onNext))
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Please wait while we sign the challenge.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            viewModel.startIfNeeded()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}

@MainActor
class PingOneRecognizeViewModel: ObservableObject {
    nonisolated(unsafe) private var task: Task<Void, Never>?
    private let callback: PingOneRecognizeCallback
    private let onNext: () -> Void
    private var hasStarted = false

    init(callback: PingOneRecognizeCallback, onNext: @escaping () -> Void) {
        self.callback = callback
        self.onNext = onNext
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        task = Task {
            do {
                try await keylessConfigure()

                let valueId = (callback.json["output"] as? [[String: Any]])?.first(where: {
                    ($0["name"] as? String) == "id"
                })?["value"] as? String ?? ""

                if valueId == "keylessEnrolment" {
                    let response = try await keylessEnroll()
                    submitResponse(response)
                } else if valueId == "keylessAuthentication" {
                    let clientState = (callback.json["output"] as? [[String: Any]])?.first(where: {
                        ($0["name"] as? String) == "value"
                    })?["value"] as? String
                    let response = try await keylessAuthenticate(clientState: clientState)
                    submitResponse(response)
                }
            } catch {
                submitError(error)
            }
        }
    }

    nonisolated func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancel()
    }

    private func keylessConfigure() async throws {
        let host = callback.host.isEmpty ? "https://auth-1.eks.core-staging.keyless.technology" : callback.host
        let setupConfig = SetupConfig(apiKey: callback.apiKey, hosts: [host])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                Keyless.configure(setupConfiguration: setupConfig) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    private func isUserEnrolledOnDevice() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            Keyless.validateUserDeviceActive { error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    private func keylessEnroll() async throws -> KeylessResponse {
        Keyless.reset()
        let jwtSigningInfo = JwtSigningInfo(claimTransactionData: "test")
        let configuration = BiomEnrollConfig(jwtSigningInfo: jwtSigningInfo, generatingClientState: .backup)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
            DispatchQueue.main.async {
                Keyless.enroll(configuration: configuration) { result in
                    switch result {
                    case .success(let success):
                        continuation.resume(returning: KeylessResponse(jwt: success.signedJwt, clientState: success.clientState, recognizeId: success.keylessId, error: nil))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func keylessAuthenticate(clientState: String?) async throws -> KeylessResponse {
        let enrolled = try await isUserEnrolledOnDevice()
        let jwtSigningInfo = JwtSigningInfo(claimTransactionData: "test")
        if enrolled {
            let configuration = BiomAuthConfig(jwtSigningInfo: jwtSigningInfo)
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                DispatchQueue.main.async {
                    Keyless.authenticate(configuration: configuration) { result in
                        switch result {
                        case .success(let success):
                            continuation.resume(returning: KeylessResponse(jwt: success.signedJwt, clientState: nil, recognizeId: nil, error: nil))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } else {
            let configuration = BiomEnrollConfig(clientState: clientState, jwtSigningInfo: jwtSigningInfo)
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                DispatchQueue.main.async {
                    Keyless.enroll(configuration: configuration) { result in
                        switch result {
                        case .success(let success):
                            continuation.resume(returning: KeylessResponse(jwt: success.signedJwt, clientState: nil, recognizeId: success.keylessId, error: nil))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    private func submitResponse(_ response: KeylessResponse) {
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            _ = callback.input(jsonString)
            onNext()
        }
    }

    private func submitError(_ error: Error) {
        let response = KeylessResponse(jwt: nil, clientState: nil, recognizeId: nil, error: error.localizedDescription)
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            _ = callback.input(jsonString)
            onNext()
        }
    }
}
