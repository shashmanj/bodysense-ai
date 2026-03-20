//
//  VideoCallView.swift
//  body sense ai
//
//  In-app video consultation with live camera preview.
//
//  ─── VIDEO CALL INTEGRATION ───────────────────────────────────────────────
//  This file provides the full call UI with local camera preview.
//  For real peer-to-peer video, integrate Agora SDK:
//
//  1. SPM: https://github.com/AgoraIO/AgoraRtcEngine_iOS
//  2. Get free App ID from https://console.agora.io
//  3. Replace AgoraCameraPreview with AgoraVideoCanvas
//  4. Replace connectMock() with:
//       let kit = AgoraRtcEngineKit.sharedEngine(withAppId: "YOUR_APP_ID", delegate: nil)
//       kit.enableVideo()
//       kit.joinChannel(byToken: nil, channelId: roomId, info: nil, uid: 0)
//  ──────────────────────────────────────────────────────────────────────────

import SwiftUI
import AVFoundation
import Observation

// MARK: - Camera Preview (AVFoundation)

@Observable
class CameraPreviewController {
    let session = AVCaptureSession()
    var currentPosition: AVCaptureDevice.Position = .front

    init() {
        setupSession()
    }

    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Input
        if let device = camera(for: currentPosition),
           let input = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(input) { session.addInput(input) }
        }
        session.commitConfiguration()
    }

    func camera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices.first
    }

    func start() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.startRunning() }
        }
    }

    func stop() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.stopRunning() }
        }
    }

    func flip() {
        currentPosition = currentPosition == .front ? .back : .front
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        if let device = camera(for: currentPosition),
           let input = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(input) { session.addInput(input) }
        }
        session.commitConfiguration()
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds ?? CGRect(x:0,y:0,width:390,height:844)
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Video Call View

struct VideoCallView: View {
    let session     : VideoCallSession
    let onEnd       : () -> Void

    @State private var camera = CameraPreviewController()
    @State private var isMuted      = false
    @State private var isCameraOff  = false
    @State private var isSpeakerOn  = true
    @State private var callDuration = 0
    @State private var callStatus   : CallStatusDisplay = .connecting
    @State private var showEndAlert = false

    nonisolated enum CallStatusDisplay: Equatable { case connecting, active }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Remote feed (doctor avatar / placeholder) ──
            remoteVideoArea

            // ── Local camera (picture-in-picture) ──
            localCameraPreview

            // ── Top bar ──
            VStack {
                // Demo mode banner
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill").font(.caption2)
                    Text("Demo Mode — Video call simulation").font(.caption2).fontWeight(.medium)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 4)

                topBar
                Spacer()
                // ── Call controls ──
                callControls
            }
        }
        .onAppear {
            camera.start()
            startTimer()
            simulateConnect()
        }
        .onDisappear { camera.stop() }
        .alert("End Call?", isPresented: $showEndAlert) {
            Button("End Call", role: .destructive) { onEnd() }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("This will end your video consultation with \(session.doctor.name).")
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Remote Video (Doctor)
    var remoteVideoArea: some View {
        ZStack {
            // Background gradient (when doctor video not yet connected)
            LinearGradient(
                colors: [Color(hex: session.doctor.avatarColor).opacity(0.8), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if callStatus == .connecting {
                VStack(spacing: 20) {
                    // Doctor avatar
                    Circle()
                        .fill(Color(hex: session.doctor.avatarColor))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(initials(session.doctor.name))
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        )
                        .shadow(radius: 20)

                    Text("Connecting to \(session.doctor.name)...")
                        .font(.headline)
                        .foregroundColor(.white)

                    ProgressView()
                        .tint(.white)
                }
            } else {
                // When connected — show doctor avatar as "remote video" placeholder
                // Replace this with Agora remote video canvas in production
                VStack {
                    Circle()
                        .fill(Color(hex: session.doctor.avatarColor).opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(initials(session.doctor.name))
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        )
                    Text(session.doctor.name)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: Local Camera (PiP)
    var localCameraPreview: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    if isCameraOff {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "video.slash.fill")
                                    .foregroundColor(.secondary)
                            )
                    } else {
                        CameraPreviewView(session: camera.session)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(width: 100, height: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.4), lineWidth: 2))
                .shadow(radius: 10)
                .padding(.trailing, 16)
                .padding(.top, 100)
            }
            Spacer()
        }
    }

    // MARK: Top Bar
    var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.doctor.name)
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(callStatus == .active ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(callStatus == .active ? timerString() : "Connecting...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
            // Encryption badge
            Label("Encrypted", systemImage: "lock.fill")
                .font(.caption2)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: Call Controls
    var callControls: some View {
        VStack(spacing: 24) {
            // Specialization tag
            Text(session.doctor.specialization)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .foregroundColor(.white)

            // Controls row
            HStack(spacing: 28) {
                callButton(
                    icon: isMuted ? "mic.slash.fill" : "mic.fill",
                    label: isMuted ? "Unmute" : "Mute",
                    color: isMuted ? .brandCoral : .white.opacity(0.2),
                    iconColor: .white
                ) { isMuted.toggle() }

                callButton(
                    icon: isCameraOff ? "video.slash.fill" : "video.fill",
                    label: isCameraOff ? "Cam On" : "Cam Off",
                    color: isCameraOff ? .brandCoral : .white.opacity(0.2),
                    iconColor: .white
                ) { isCameraOff.toggle() }

                callButton(
                    icon: "arrow.triangle.2.circlepath.camera.fill",
                    label: "Flip",
                    color: .white.opacity(0.2),
                    iconColor: .white
                ) { camera.flip() }

                callButton(
                    icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.slash.fill",
                    label: isSpeakerOn ? "Speaker" : "Speaker Off",
                    color: .white.opacity(0.2),
                    iconColor: .white
                ) { isSpeakerOn.toggle() }
            }

            // End call button
            Button { showEndAlert = true } label: {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    )
                    .shadow(color: .red.opacity(0.4), radius: 12)
            }

            Spacer().frame(height: 8)
        }
        .padding(.bottom, 40)
    }

    func callButton(icon: String, label: String, color: Color, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(iconColor)
                    )
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: Helpers
    func initials(_ name: String) -> String {
        name.components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2)
            .joined()
    }

    func timerString() -> String {
        let m = callDuration / 60
        let s = callDuration % 60
        return String(format: "%02d:%02d", m, s)
    }

    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if callStatus == .active { callDuration += 1 }
        }
    }

    func simulateConnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { callStatus = .active }
        }
    }
}
