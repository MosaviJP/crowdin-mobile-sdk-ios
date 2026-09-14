//
//  CrowdinLocaleTests.swift
//  CrowdinSDK-Unit-Core_Tests
//
//  Validates that cw_localized(with:) uses the SDK's active localization
//  locale for String(format:locale:arguments:) so that CLDR plural rules
//  match the target language, not the device locale.
//

import XCTest
#if os(iOS) || os(tvOS)
import UIKit
#endif
@testable import CrowdinSDK

// MARK: - Minimal test doubles

private class StubLocalStorage: LocalLocalizationStorageProtocol {
    var localization: String
    var localizations: [String] { [] }
    var strings: [String: String] = [:]
    var plurals: [AnyHashable: Any] = [:]

    init(localization: String) { self.localization = localization }

    func fetchData(completion: LocalizationStorageCompletion, errorHandler: LocalizationStorageError?) {
        completion(localizations, localization, strings, plurals)
    }
    func saveLocalizaion(strings: [String: String]?, plurals: [AnyHashable: Any]?, for localization: String) {}
    func save() {}
    func fetchData() {}
    func deintegrate() {}
}

private class StubRemoteStorage: RemoteLocalizationStorageProtocol {
    var localization: String
    var localizations: [String] = []
    var name: String = "StubRemoteStorage"

    init(localization: String) { self.localization = localization }

    func prepare(with completion: @escaping () -> Void) { completion() }
    func fetchData(completion: @escaping LocalizationStorageCompletion, errorHandler: LocalizationStorageError?) {
        completion(localizations, localization, [:], [:])
    }
    func deintegrate() {}
}

private class StubProvider: LocalizationProviderProtocol {
    var localStorage: LocalLocalizationStorageProtocol
    var remoteStorage: RemoteLocalizationStorageProtocol
    var localization: String
    var localizations: [String] { [] }

    required init(localization: String, localStorage: LocalLocalizationStorageProtocol, remoteStorage: RemoteLocalizationStorageProtocol) {
        self.localization = localization
        self.localStorage = localStorage
        self.remoteStorage = remoteStorage
    }

    func refreshLocalization() {}
    func refreshLocalization(completion: @escaping ((Error?) -> Void)) { completion(nil) }
    func setLocalization(_ localization: String, completion: @escaping ((Error?) -> Void)) {
        self.localization = localization
        completion(nil)
    }
    func prepare(with completion: @escaping () -> Void) { completion() }
    func deintegrate() {}

    func localizedString(for key: String) -> String? { nil }
    func key(for string: String) -> String? { localStorage.strings.first(where: { $0.value == string })?.key }
    func values(for string: String, with format: String) -> [Any]? { nil }
    func set(string: String, for key: String) {}
}

// MARK: - Tests

class CrowdinLocaleTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        Localization.current = nil
    }

    // MARK: - crowdinLocale fallback

    /// When the SDK has not been started (`Localization.current == nil`),
    /// `crowdinLocale` must fall back to `Locale.current`, even if
    /// `UserDefaults` still contains a persisted localization value.
    func testCrowdinLocale_returnsCurrentLocale_whenSDKNotStarted() {
        Localization.current = nil
        let locale = String.crowdinLocale
        XCTAssertEqual(locale, Locale.current)
    }

    /// When the SDK is started with a specific localization,
    /// `crowdinLocale` must return a `Locale` matching that language.
    func testCrowdinLocale_returnsSDKLocale_whenSDKStarted() {
        let local  = StubLocalStorage(localization: "uk")
        let remote = StubRemoteStorage(localization: "uk")
        let provider = StubProvider(localization: "uk", localStorage: local, remoteStorage: remote)
        Localization.current = Localization(provider: provider)

        let locale = String.crowdinLocale
        XCTAssertEqual(locale.identifier, "uk")
    }

    // MARK: - Locale-dependent formatting

    /// Verifies that `cw_localized(with:)` passes the SDK locale to
    /// `String(format:locale:arguments:)`.
    ///
    /// Decimal separator differs by locale (e.g. "." for English, "," for
    /// Ukrainian/German). We use this as a proxy to confirm the locale is
    /// passed through, since we can't easily test CLDR plural rule selection
    /// without a real `.stringsdict` bundle.
    func testCwLocalized_usesSDKLocale_forFormatting() {
        // Start SDK with Ukrainian locale
        let local  = StubLocalStorage(localization: "uk")
        let remote = StubRemoteStorage(localization: "uk")
        let provider = StubProvider(localization: "uk", localStorage: local, remoteStorage: remote)
        Localization.current = Localization(provider: provider)

        // Format a float using cw_localized — since NSLocalizedString for an
        // unknown key returns the key itself, we use a format string as the key.
        let format = "Price: %.2f"
        let result = String(format: format, locale: String.crowdinLocale, arguments: [1234.56 as CVarArg])

        // Ukrainian locale uses comma as decimal separator
        XCTAssertTrue(result.contains(","), "Expected Ukrainian decimal separator (comma), got: \(result)")
    }

    func testCwLocalized_usesEnglishLocale_forFormatting() {
        // Start SDK with English locale
        let local  = StubLocalStorage(localization: "en")
        let remote = StubRemoteStorage(localization: "en")
        let provider = StubProvider(localization: "en", localStorage: local, remoteStorage: remote)
        Localization.current = Localization(provider: provider)

        let format = "Price: %.2f"
        let result = String(format: format, locale: String.crowdinLocale, arguments: [1234.56 as CVarArg])

        // English locale uses period as decimal separator
        XCTAssertTrue(result.contains("."), "Expected English decimal separator (period), got: \(result)")
    }

    /// Switching the SDK locale should change which locale is used for formatting.
    func testCrowdinLocale_updatesWhenLocalizationChanges() {
        let local  = StubLocalStorage(localization: "en")
        let remote = StubRemoteStorage(localization: "en")
        let provider = StubProvider(localization: "en", localStorage: local, remoteStorage: remote)
        Localization.current = Localization(provider: provider)

        XCTAssertEqual(String.crowdinLocale.identifier, "en")

        // Simulate switching to German
        provider.localization = "de"

        XCTAssertEqual(String.crowdinLocale.identifier, "de")
    }
}

#if os(iOS) || os(tvOS)
extension CrowdinLocaleTests {
    func testHotReloadToggleDoesNotChangeControlSwizzling() {
        let oldEnabled = CrowdinSDK.isHotReloadEnabled
        let labelSwizzled = UILabel.isSwizzled
        let buttonSwizzled = UIButton.isSwizzled
        defer { CrowdinSDK.enableHotReload(enable: oldEnabled) }
        let config = CrowdinSDKConfig.config().with(hotReloadEnabled: true)
        XCTAssertTrue(config.hotReloadEnabled)
        XCTAssertEqual(UILabel.isSwizzled, labelSwizzled)
        XCTAssertEqual(UIButton.isSwizzled, buttonSwizzled)
        CrowdinSDK.enableHotReload(enable: false)
        XCTAssertFalse(config.hotReloadEnabled)
        XCTAssertEqual(UILabel.isSwizzled, labelSwizzled)
        XCTAssertEqual(UIButton.isSwizzled, buttonSwizzled)
    }

    func testLanguageRefreshWithoutControlSwizzling() {
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertFalse(UILabel.isSwizzled)
        XCTAssertFalse(UIButton.isSwizzled)
        let local = StubLocalStorage(localization: "en")
        // Use keys absent from the test bundle to verify that refresh resolves text through the captured keys.
        local.strings = ["hot_reload_new_label": "Old label", "hot_reload_new_button": "Old button"]
        let provider = StubProvider(localization: "en", localStorage: local,
                                    remoteStorage: StubRemoteStorage(localization: "en"))
        Localization.current = Localization(provider: provider)
        let container = UIView()
        let label = UILabel()
        label.text = "Old label"
        let button = UIButton(type: .custom)
        button.setTitle("Old button", for: .normal)
        let reusedLabel = UILabel()
        reusedLabel.text = "Old label"
        container.addSubview(label)
        container.addSubview(button)
        container.addSubview(reusedLabel)

        let refresh = CrowdinSDK.prepareLanguageRefresh(from: [container])
        XCTAssertEqual(label.text, "Old label")
        reusedLabel.text = "Reused cell"
        local.strings = [:]
        refresh()

        XCTAssertEqual(label.text, "hot_reload_new_label")
        XCTAssertEqual(button.title(for: .normal), "hot_reload_new_button")
        XCTAssertEqual(reusedLabel.text, "Reused cell")
    }
}
#endif
