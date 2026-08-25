import AVFoundation
import Foundation

enum CameraAuthorization: Sendable {
    case authorized
    case denied
    case restricted
}

protocol CameraPermissionProviding: Sendable {
    func request() async -> CameraAuthorization
    func current() -> CameraAuthorization?
}

struct SystemCameraPermissionService: CameraPermissionProviding {
    func request() async -> CameraAuthorization {
        #if targetEnvironment(simulator)
        return .authorized
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        @unknown default:
            return .denied
        }
        #endif
    }

    func current() -> CameraAuthorization? {
        #if targetEnvironment(simulator)
        return .authorized
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return nil
        @unknown default: return .denied
        }
        #endif
    }
}

