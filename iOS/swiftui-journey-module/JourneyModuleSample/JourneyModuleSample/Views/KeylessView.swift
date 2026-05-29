//
//  KeylessView.swift
//  JourneyModuleSample
//
//  Created by george bafaloukas on 08/01/2026.
//

import PingJourney
import SwiftUI
import KeylessSDK

struct KeylessView: View {
    //    let viewModel = KeylessViewModel()
    let callback: PingOneRecognizeCallback
    let onNext: () -> Void
    @State private var hasStarted = false

    var body: some View {
        VStack {
            Text("Device Signing")
                .font(.title)
            Text("Please wait while we sign the challenge.")
                .font(.body)
                .padding()
            ProgressView()
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            handleKeyless()
        }
    }
    
    func keylessConfigure() async throws {
        let host = callback.host.isEmpty ? "https://auth-1.eks.core-staging.keyless.technology" : callback.host
        print("[KeylessView] Configuring Keyless SDK with apiKey: \(callback.apiKey), host: \(host)")
        let setupConfig = SetupConfig(
            apiKey: callback.apiKey,
            hosts: [host]
        )
        
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
    
    func isUserEnrolledOnDevice() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            Keyless.validateUserDeviceActive(
                completionHandler: { error in
                    if let error = error {
                        print("Keyless User or device deactivated: performing a reset")
                        // error code 1131 = user is not enrolled on the device (not even locally so did not check on backend)
                        // error code 534 = user not found or deactivated on backend
                        // error code 535 = device not found or deactivated on backend
                        
                        continuation.resume(returning: (false))
                    } else {
                        print("Keyless User and device active")
                        continuation.resume(returning: (true))
                    }
                }
            )
        }
    }
    
    func keylessEnroll() async throws -> KeylessResponse? {
        Keyless.reset()
        let opts = callback.mobileSDKOptions
        
        let txData = callback.transactionData.isEmpty ? "test" : callback.transactionData
        let jwtSigningInfo = JwtSigningInfo(claimTransactionData: txData)
        
        let livenessConfig = opts["livenessConfiguration"].flatMap { Keyless.LivenessConfiguration(rawValue: $0) } ?? .LEVEL_1
        let livenessEnvAware = opts["livenessEnvironmentAware"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_LIVENESS_ENV_AWARE
        let cameraDelay = opts["cameraDelaySeconds"].flatMap(Int.init) ?? BiomEnrollConfig.DEFAULT_DELAY
        let shouldRetrieveFrame = opts["shouldRetrieveEnrollmentFrame"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOULD_RETRIEVE_ENROLLMENT_FRAME
        let showSuccess = opts["showSuccessFeedback"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK
        let showFailure = opts["showFailureFeedback"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOW_FAILURE_FEEDBACK
        let showInstructions = opts["showInstructionsScreen"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN
        let generatingClientState: ClientStateType? = callback.generateClientState ? .backup : nil
        let clientState: String? = callback.clientState.isEmpty ? nil : callback.clientState

        let configuration = BiomEnrollConfig(
            clientState: clientState,
            jwtSigningInfo: jwtSigningInfo,
            livenessConfiguration: livenessConfig,
            livenessEnvironmentAware: livenessEnvAware,
            cameraDelaySeconds: cameraDelay,
            generatingClientState: generatingClientState,
            shouldRetrieveEnrollmentFrame: shouldRetrieveFrame,
            showInstructionsScreen: showInstructions,
            showSuccessFeedback: showSuccess,
            showFailureFeedback: showFailure
        )
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
            DispatchQueue.main.async {
                Keyless.enroll(
                    configuration: configuration,
                    onCompletion: { result in
                        switch result {
                        case .success(let enrollmentSuccess):
                            print("Enrollment finished successfully. UserID: \(enrollmentSuccess.keylessId ?? "")")
                            let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: enrollmentSuccess.clientState, recognizeId: enrollmentSuccess.keylessId, error: nil)
                            continuation.resume(returning: (response))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                            print("Enrollment finished with error: \(error.message)")
                        }
                    })
            }
        }
        return response
    }
    
    func keylessAuthenticate(clientState: String?) async throws -> KeylessResponse? {
        do {
            let enrolled = try await isUserEnrolledOnDevice()

            let opts = callback.mobileSDKOptions

            let txData = callback.transactionData.isEmpty ? "test" : callback.transactionData
            let jwtSigningInfo = JwtSigningInfo(claimTransactionData: txData)
            
            let livenessConfig = opts["livenessConfiguration"].flatMap { Keyless.LivenessConfiguration(rawValue: $0) } ?? .LEVEL_1
            let livenessEnvAware = opts["livenessEnvironmentAware"].map { $0.lowercased() == "true" } ?? BiomAuthConfig.DEFAULT_LIVENESS_ENV_AWARE
            let cameraDelay = opts["cameraDelaySeconds"].flatMap(Int.init) ?? BiomAuthConfig.DEFAULT_CAMERA_DELAY_SECONDS
            let showSuccess = opts["showSuccessFeedback"].map { $0.lowercased() == "true" } ?? BiomAuthConfig.DEFAULT_SHOW_SUCCESS_FEEDBACK
            
            if enrolled {
                let configuration = BiomAuthConfig(
                    livenessConfiguration: livenessConfig,
                    livenessEnvironmentAware: livenessEnvAware,
                    cameraDelaySeconds: cameraDelay,
                    showSuccessFeedback: showSuccess,
                    jwtSigningInfo: jwtSigningInfo
                )
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                    DispatchQueue.main.async {
                        Keyless.authenticate(
                            configuration: configuration,
                            onCompletion: { result in
                                switch result {
                                case .success(let enrollmentSuccess):
                                    print("Authentication finished successfully.")
                                    let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: nil, recognizeId: nil, error: nil)
                                    continuation.resume(returning: (response))
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                    print("Authentication finished with error: \(error.message)")
                                }
                            })
                    }
                }
                return response
            } else {
                let showInstructions = opts["showInstructionsScreen"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOW_INSTRUCTIONS_SCREEN
                let showFailure = opts["showFailureFeedback"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOW_FAILURE_FEEDBACK
                let shouldRetrieveFrame = opts["shouldRetrieveEnrollmentFrame"].map { $0.lowercased() == "true" } ?? BiomEnrollConfig.DEFAULT_SHOULD_RETRIEVE_ENROLLMENT_FRAME
                
                let configuration = BiomEnrollConfig(
                    clientState: clientState,
                    jwtSigningInfo: jwtSigningInfo,
                    livenessConfiguration: livenessConfig,
                    livenessEnvironmentAware: livenessEnvAware,
                    cameraDelaySeconds: cameraDelay,
                    shouldRetrieveEnrollmentFrame: shouldRetrieveFrame,
                    showInstructionsScreen: showInstructions,
                    showSuccessFeedback: showSuccess,
                    showFailureFeedback: showFailure
                )
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                    DispatchQueue.main.async {
                        Keyless.enroll(
                            configuration: configuration,
                            onCompletion: { result in
                                switch result {
                                case .success(let enrollmentSuccess):
                                    print("Authentication finished successfully.")
                                    let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: nil, recognizeId: enrollmentSuccess.keylessId, error: nil)
                                    continuation.resume(returning: (response))
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                    print("Authentication finished with error: \(error.message)")
                                }
                            })
                    }
                }
                return response
            }
        } catch {
            return nil
        }
    }
    
    func handleKeyless() -> Void {
        Task { @MainActor in
            do {
                try await keylessConfigure()

                if callback.operationType == "ENROLL" {
                    let keylessPayload = try await keylessEnroll()
                    if let jwt = keylessPayload?.jwt {
                        print("[KeylessView] Setting signedJwt: \(jwt)")
                        callback.setSignedJwt(jwt)
                    }
                    if let clientState = keylessPayload?.clientState {
                        print("[KeylessView] Setting inputClientState: \(clientState)")
                        callback.setInputClientState(clientState)
                    }
                    if let recognizeId = keylessPayload?.recognizeId {
                        print("[KeylessView] Setting recognizeId: \(recognizeId)")
                        callback.setRecognizeId(recognizeId)
                    }
                    onNext()
                } else if callback.operationType == "AUTHENTICATE" {
                    print("[KeylessView] Authenticating with clientState: \(callback.clientState)")
                    let keylessPayload = try await keylessAuthenticate(clientState: callback.clientState.isEmpty ? nil : callback.clientState)
                    if let jwt = keylessPayload?.jwt {
                        print("[KeylessView] Setting signedJwt: \(jwt)")
                        callback.setSignedJwt(jwt)
                    }
                    onNext()
                }
            } catch {
                print("[KeylessView] Keyless Error: \(error)")
                if let keylessError = error as? KeylessSDKError {
                    callback.setClientError(keylessError.title)
                } else {
                    callback.setClientError(error.localizedDescription)
                }
                onNext()
            }
        }
    }
}

struct KeylessPayload: Codable {
    let keylessAPIKey: String
    let keylessHost: String
    let op_id: String
}

struct KeylessResponse: Codable {
    let jwt: String?
    let clientState: String?
    let recognizeId: String?
    let error: String?
}
