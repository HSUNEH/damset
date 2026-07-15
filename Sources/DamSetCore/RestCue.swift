import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif
#if os(iOS)
import AVFoundation
import UIKit
#endif

enum RestCuePlan: Equatable, Sendable {
    case schedule(resumeAt: Date, upcomingExercise: String?)
    case cancel
}

public enum RestNotificationAuthorizationState: Equatable, Sendable {
    case unavailable
    case notDetermined
    case denied
    case authorized
    case authorizedWithoutSound
    case failed(String)
}

struct RestCueNotificationSpec: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String?
    let delay: TimeInterval
    let soundFileName: String
}

/// Schedules one self-ending notification sound containing the complete
/// "3, 2, 1, go" sequence. It needs no tap or dismissal and works while the
/// app is locked, backgrounded, or terminated when notification sounds are on.
public enum RestCueScheduler {
    public static let cueIdentifiers = [
        "damset.restcue.countdown",
        "damset.restcue.start"
    ]
    public static let countdownSoundFileName = "RestCountdown.wav"
    public static let startSoundFileName = "RestStart.wav"
    public static let tickSoundFileName = "RestTick.wav"

    /// UNUserNotificationCenter traps in processes without a bundle identifier
    /// (e.g. the SwiftPM shell executable), so notification work is skipped there.
    private static var notificationsAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    public static func authorizationState() async -> RestNotificationAuthorizationState {
        #if canImport(UserNotifications)
        guard notificationsAvailable else { return .unavailable }
        return mapAuthorization(await UNUserNotificationCenter.current().notificationSettings())
        #else
        return .unavailable
        #endif
    }

    public static func requestAuthorization() async -> RestNotificationAuthorizationState {
        #if canImport(UserNotifications)
        guard notificationsAvailable else { return .unavailable }
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        guard current.authorizationStatus == .notDetermined else {
            return mapAuthorization(current)
        }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            return mapAuthorization(await center.notificationSettings())
        } catch {
            return .failed(error.localizedDescription)
        }
        #else
        return .unavailable
        #endif
    }

    static func plan(for session: WorkoutRoutineSession) -> RestCuePlan {
        guard session.sessionStatus == .resting,
              session.lockScreenState.phase == .resting,
              let resumeAt = session.lockScreenState.resumeAt else {
            return .cancel
        }
        return .schedule(
            resumeAt: resumeAt,
            upcomingExercise: session.nextPlannedSet?.exerciseName
        )
    }

    static func notificationSpec(
        resumeAt: Date,
        upcomingExercise: String?,
        now: Date
    ) -> RestCueNotificationSpec? {
        let countdownDelay = resumeAt.addingTimeInterval(-3).timeIntervalSince(now)
        if countdownDelay > 0.5 {
            return RestCueNotificationSpec(
                identifier: cueIdentifiers[0],
                title: "Next set in 3…",
                body: upcomingExercise,
                delay: countdownDelay,
                soundFileName: countdownSoundFileName
            )
        }

        let startDelay = resumeAt.timeIntervalSince(now)
        guard startDelay > 0.5 else { return nil }
        return RestCueNotificationSpec(
            identifier: cueIdentifiers[1],
            title: "Next set — go!",
            body: upcomingExercise,
            delay: startDelay,
            soundFileName: startSoundFileName
        )
    }

    /// The combined sound starts three seconds before the deadline and ends
    /// with the go cue at `resumeAt`. For a newly shortened rest under three
    /// seconds, a standalone go cue is scheduled at the deadline instead.
    public static func scheduleRestEndCue(resumeAt: Date, upcomingExercise: String?, now: Date = Date()) {
        #if canImport(UserNotifications)
        guard notificationsAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: cueIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: cueIdentifiers)
        guard let spec = notificationSpec(
            resumeAt: resumeAt,
            upcomingExercise: upcomingExercise,
            now: now
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = spec.title
        if let body = spec.body { content.body = body }
        content.threadIdentifier = "damset.restcue"
        content.sound = UNNotificationSound(
            named: UNNotificationSoundName(rawValue: spec.soundFileName)
        )
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: spec.delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: spec.identifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error {
                NSLog("DamSet rest cue could not be scheduled: %@", error.localizedDescription)
            }
        }
        #endif
    }

    public static func cancelPendingCues() {
        #if canImport(UserNotifications)
        guard notificationsAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: cueIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: cueIdentifiers)
        #endif
    }

    #if canImport(UserNotifications)
    private static func mapAuthorization(
        _ settings: UNNotificationSettings
    ) -> RestNotificationAuthorizationState {
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .ephemeral:
            let canSoundOnLockScreen = settings.soundSetting == .enabled
                && settings.lockScreenSetting == .enabled
            return canSoundOnLockScreen ? .authorized : .authorizedWithoutSound
        case .provisional:
            return .authorizedWithoutSound
        @unknown default:
            return .unavailable
        }
    }
    #endif
}

/// Plays the same short gym cue while DamSet is foregrounded. Existing music
/// or video audio is ducked, never stopped, then restored immediately after the
/// cue with `notifyOthersOnDeactivation`.
@MainActor
public final class InAppRestCuePlayer {
    #if os(iOS)
    private var audioPlayer: AVAudioPlayer?
    #endif
    private var lastAnnouncedSecond: Int?
    private var countdownSequenceStarted = false
    private var audioSessionGeneration = 0

    public init() {}

    /// Feed once per second while resting. A combined file keeps the three
    /// ticks and the final go cue rhythmically aligned without interrupting
    /// whatever the user was already listening to.
    public func handleRestTick(remainingSeconds: Int) {
        guard (0...3).contains(remainingSeconds),
              remainingSeconds != lastAnnouncedSecond else { return }
        lastAnnouncedSecond = remainingSeconds
        #if os(iOS)
        switch remainingSeconds {
        case 3:
            countdownSequenceStarted = playSound(
                named: RestCueScheduler.countdownSoundFileName
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case 1...2 where !countdownSequenceStarted:
            _ = playSound(named: RestCueScheduler.tickSoundFileName)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case 0:
            if !countdownSequenceStarted {
                _ = playSound(named: RestCueScheduler.startSoundFileName)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        default:
            break
        }
        #endif
    }

    /// Call when a new rest begins or the workout moves on, so the next
    /// countdown announces again.
    public func reset() {
        lastAnnouncedSecond = nil
        countdownSequenceStarted = false
        audioSessionGeneration &+= 1
        #if os(iOS)
        audioPlayer?.stop()
        audioPlayer = nil
        restoreAudioSession()
        #endif
    }

    #if os(iOS)
    @discardableResult
    private func playSound(named fileName: String) -> Bool {
        let file = fileName as NSString
        guard let url = Bundle.main.url(
            forResource: file.deletingPathExtension,
            withExtension: file.pathExtension
        ) else { return false }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            guard player.play() else { return false }
            audioPlayer = player

            audioSessionGeneration &+= 1
            let generation = audioSessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.15) { [weak self] in
                guard let self, self.audioSessionGeneration == generation else { return }
                self.audioPlayer = nil
                self.restoreAudioSession()
            }
            return true
        } catch {
            restoreAudioSession()
            return false
        }
    }

    private func restoreAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
    }
    #endif
}
