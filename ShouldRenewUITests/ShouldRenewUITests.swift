import XCTest

/// 关键路径回归（真机流程走查）：
/// - 反馈 4：选中模板后详情名称自动填充
/// - 反馈 2：清单点入决策页再返回，记录仍在
/// - 反馈 3：决策页提供使用次数滑动条
final class ShouldRenewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddFromTemplateThenListTapSurvivesNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-fresh"]
        app.launch()

        // 添加页：选择模板 → 名称自动填充
        app.tabBars.buttons["添加"].tap()
        let templateRow = app.buttons.matching(NSPredicate(format: "label CONTAINS '模板'")).firstMatch
        XCTAssertTrue(templateRow.waitForExistence(timeout: 5), "添加页应显示模板选择")
        templateRow.tap()
        let claudeMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Claude Pro'")).firstMatch
        XCTAssertTrue(claudeMenu.waitForExistence(timeout: 5), "模板菜单应包含 Claude Pro")
        claudeMenu.tap()

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Claude Pro", "选中模板后名称应自动填充")

        app.buttons["保存"].tap()

        // 清单：点击记录进入决策页，返回后记录仍在
        app.tabBars.buttons["清单"].tap()
        let row = app.staticTexts["Claude Pro"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "清单应显示刚添加的订阅")

        row.tap()
        let headline = app.staticTexts["该不该续「Claude Pro」？"]
        XCTAssertTrue(headline.waitForExistence(timeout: 5), "应进入决策页")

        // 反馈 3：决策页有使用次数滑动条
        XCTAssertTrue(app.sliders.firstMatch.waitForExistence(timeout: 5), "决策页应有使用次数滑动条")

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Claude Pro"].firstMatch.waitForExistence(timeout: 5),
                      "返回清单后记录仍应显示")
    }
}
