import XCTest

/// xuma-prd-for-ai.md 验收走查：
/// A1 冷启动空态 → 目录添加 Claude Pro → 今日即将到期 + 清单生效中可见
/// A7 Tab 只有 今日/清单/设置，无月报
final class ShouldRenewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddFromCatalogRenewAndTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-fresh"]
        app.launch()

        // A7：三个一级入口，无月报
        XCTAssertEqual(app.tabBars.buttons.count, 3, "应只有 今日/清单/设置 三个 Tab")
        XCTAssertFalse(app.tabBars.buttons["月报"].exists)

        // A1：空态 → 添加 AI 会员
        XCTAssertTrue(app.staticTexts["最近没有要决定的"].waitForExistence(timeout: 5))
        app.buttons["添加 AI 会员"].tap()

        // 目录列表 → Claude Pro → 表单自动带出默认价与名称
        let claudeRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Claude Pro'")).firstMatch
        XCTAssertTrue(claudeRow.waitForExistence(timeout: 5), "目录应包含 Claude Pro")
        claudeRow.tap()

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Claude Pro", "选中目录项后名称应带出")

        app.buttons["保存"].tap()

        // 新目录项默认 30 天后扣款，在 14 天决策窗外：今日仍为空态，但「即将到期」列出
        XCTAssertTrue(app.staticTexts["最近没有要决定的"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["即将到期"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Claude Pro"].firstMatch.waitForExistence(timeout: 5),
                      "今日「即将到期」应显示新添加的订阅")

        // 清单：生效中分区可见（A1）
        app.tabBars.buttons["清单"].tap()
        XCTAssertTrue(app.staticTexts["生效中"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Claude Pro"].firstMatch.waitForExistence(timeout: 5))
    }
}

/// 录制产品演示视频：外部用 `simctl io recordVideo` 录主模拟器，
/// 本测试负责真实驱动界面（-parallel-testing-enabled NO 时跑在主模拟器上）。
/// 开头 sleep(12) 给录制脚本留启动时间，片头由后期裁剪。
final class DemoRecordingUITests: XCTestCase {
    func testRecordDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-fresh", "--uitest-demo"]
        sleep(12)
        app.launch()

        sleep(2) // 空态停留
        app.buttons["添加 AI 会员"].tap()
        sleep(2) // 目录列表
        let claudeRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Claude Pro'")).firstMatch
        claudeRow.tap()
        sleep(2) // 表单（名称/价格已带出）
        app.buttons["保存"].tap()
        sleep(3) // 决策卡出现

        app.buttons["先取消"].firstMatch.tap()
        sleep(3) // 取消指南 4 步
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1) // 回到决策卡

        app.buttons["续"].firstMatch.tap()
        sleep(3) // 已标记续费 + 撤销，卡片消失

        app.tabBars.buttons["清单"].tap()
        sleep(3) // 已标记续费分区
        app.staticTexts["Claude Pro"].firstMatch.tap()
        sleep(2) // 编辑表单
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        app.tabBars.buttons["设置"].tap()
        sleep(3) // 设置页收尾
    }
}
