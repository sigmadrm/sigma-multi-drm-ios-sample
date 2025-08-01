//
//  sigma_multi_drm_ios_sampleUITestsLaunchTests.swift
//  sigma-multi-drm-ios-sampleUITests
//
//  Created by DinhPhuc on 01/08/2025.
//

import XCTest

class sigma_multi_drm_ios_sampleUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
