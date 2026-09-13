import XCTest
@testable import ShouldRenewCore

@MainActor
final class ShouldRenewCoreTests: XCTestCase {
    let cal = Calendar.current

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10, _ mi: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: mi))!
    }

    private func item(
        name: String = "Claude Pro",
        amount: Decimal = 20,
        currency: CurrencyCode = .USD,
        cycle: BillingCycle = .monthly,
        charge: Date,
        status: SubStatus = .active,
        usageMark: Int? = nil,
        renewedForChargeOn: Date? = nil,
        snoozedForChargeOn: Date? = nil,
        snoozeRequestedAt: Date? = nil
    ) -> Subscription {
        var sub = Subscription(
            name: name,
            amount: amount,
            currency: currency,
            cycle: cycle,
            nextChargeOn: charge,
            usageMark: usageMark,
            status: status
        )
        sub.renewedForChargeOn = renewedForChargeOn
        sub.snoozedForChargeOn = snoozedForChargeOn
        sub.snoozeRequestedAt = snoozeRequestedAt
        return sub
    }

    // MARK: - 目录（需求 7.2）

    func testCatalogLoadsFromJSONWithAtLeast20Templates() {
        let catalog = CatalogStore()
        XCTAssertGreaterThanOrEqual(catalog.templates.count, 20, "MVP 预置目录至少 20 条")
        let keys = catalog.templates.map(\.key)
        XCTAssertEqual(keys.count, Set(keys).count, "模板 key 不得重复")
        for template in catalog.templates {
            XCTAssertFalse(template.name.isEmpty)
            XCTAssertFalse(template.emoji.isEmpty)
            XCTAssertGreaterThan(template.defaultAmount, 0)
        }
    }

    func testCatalogCoversSpecProducts() {
        let catalog = CatalogStore()
        for key in ["chatgpt_plus", "chatgpt_pro", "claude_pro", "claude_max", "gemini_advanced",
                    "grok", "kimi", "qwen", "wenxin", "cursor_pro", "github_copilot", "windsurf",
                    "perplexity_pro", "midjourney", "runway", "jimeng", "kling", "notion_ai"] {
            XCTAssertNotNil(catalog.template(forKey: key), "缺少需求 7.2 指定产品: \(key)")
        }
    }

    func testMakeDraftCarriesTemplateDefaults() {
        let catalog = CatalogStore()
        guard let draft = catalog.makeDraft(templateKey: "claude_pro") else {
            return XCTFail("claude_pro 模板应存在")
        }
        XCTAssertEqual(draft.name, "Claude Pro")
        XCTAssertEqual(draft.amount, 20)
        XCTAssertEqual(draft.currency, .USD)
        XCTAssertEqual(draft.channel, .official)
        XCTAssertEqual(draft.purpose, .writing)
        XCTAssertEqual(draft.status, .active)
    }

    // MARK: - 取消指南（需求 7.4）

    func testEveryChannelHasFourStepsWithProductNameSubstituted() {
        let store = CancelGuideStore()
        for channel in PayChannel.allCases {
            let steps = store.steps(for: channel, product: "Kimi 会员")
            XCTAssertEqual(steps.count, 4, "\(channel) 指南应为 4 步")
            for step in steps {
                XCTAssertFalse(step.text.isEmpty)
                XCTAssertFalse(step.text.contains("{name}"), "占位符必须替换")
            }
        }
        let wechat = store.steps(for: .wechat, product: "Kimi 会员")
        XCTAssertTrue(wechat.contains { $0.text.contains("扣费服务") })
        let alipay = store.steps(for: .alipay, product: "通义千问会员")
        XCTAssertTrue(alipay.contains { $0.text.contains("免密支付/自动扣款") })
        let apple = store.steps(for: .apple, product: "Claude Pro")
        XCTAssertTrue(apple.contains { $0.text.contains("取消订阅") })
    }

    // MARK: - 提醒规划（需求 7.3 / 12.1）

    func testStandardRemindersScheduleAt731() {
        let now = date(2026, 9, 12, 10, 0)
        let item = item(charge: date(2026, 9, 22))
        let plan = ReminderPlanner.standardReminders(items: [item], reminderDays: [7, 3, 1], now: now, calendar: cal)
        XCTAssertEqual(plan.map(\.identifier), [item.id.uuidString + "-d7", item.id.uuidString + "-d3", item.id.uuidString + "-d1"])

        for reminder in plan {
            let comps = cal.dateComponents([.hour, .minute], from: reminder.fireAt)
            XCTAssertEqual(comps.hour, 9)
            XCTAssertEqual(comps.minute, 30)
            XCTAssertEqual(reminder.title, "续吗？")
        }
        let d3 = plan[1].body
        XCTAssertEqual(d3, "Claude Pro 3天后扣 $20。这个月你还用吗？")
    }

    func testBodyCopyMatchesSpecExamples() {
        XCTAssertEqual(ReminderPlanner.body(name: "Claude Pro", amountText: "¥144", daysBefore: 2), "Claude Pro 后天扣 ¥144。这个月你还用吗？")
        XCTAssertEqual(ReminderPlanner.body(name: "Cursor Pro", amountText: "$20", daysBefore: 2), "Cursor Pro 后天扣 $20。这个月你还用吗？")
        XCTAssertEqual(ReminderPlanner.dayText(0), "今天")
        XCTAssertEqual(ReminderPlanner.dayText(1), "明天")
        XCTAssertEqual(ReminderPlanner.dayText(2), "后天")
        XCTAssertEqual(ReminderPlanner.dayText(5), "5天后")
    }

    func testMissedMorningReminderBumpsToSoonWhenChargeNotPassed() {
        // 扣款日明天，现在是今天下午 → 1天档已过上午 9:30，应补推（两分钟后），保证「改成明天能收到通知」
        let now = date(2026, 9, 12, 15, 0)
        let item = item(charge: date(2026, 9, 13))
        let plan = ReminderPlanner.standardReminders(items: [item], reminderDays: [7, 3, 1], now: now, calendar: cal)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].fireAt.timeIntervalSince(now), ReminderPlanner.bumpDelay, accuracy: 1)
        XCTAssertEqual(plan[0].body, "Claude Pro 明天扣 $20。这个月你还用吗？")
    }

    func testNoReminderOnOrAfterChargeDay() {
        let now = date(2026, 9, 12, 15, 0)
        let item = item(charge: date(2026, 9, 12))  // 今天扣款
        let plan = ReminderPlanner.standardReminders(items: [item], reminderDays: [7, 3, 1], now: now, calendar: cal)
        XCTAssertTrue(plan.isEmpty)
    }

    func testSentKeysSuppressDuplicateReminders() {
        let now = date(2026, 9, 12, 10, 0)
        let item = item(charge: date(2026, 9, 22))
        let chargeStart = cal.startOfDay(for: item.nextChargeOn)
        let sent: Set<String> = [ReminderPlanner.sentKey(item: item, daysBefore: 7, chargeStart: chargeStart)]
        let plan = ReminderPlanner.standardReminders(items: [item], reminderDays: [7, 3, 1], now: now, sentKeys: sent, calendar: cal)
        XCTAssertEqual(plan.count, 2)
        XCTAssertFalse(plan.contains { $0.identifier.hasSuffix("-d7") })
    }

    func testRenewDecisionSuppressesRemindersForThatCycleOnly() {
        let now = date(2026, 9, 12, 10, 0)
        var renewed = item(charge: date(2026, 10, 1), renewedForChargeOn: date(2026, 10, 1))
        XCTAssertTrue(ReminderPlanner.standardReminders(items: [renewed], reminderDays: [7, 3, 1], now: now, calendar: cal).isEmpty)

        // 下个周期扣款日变了 → 恢复提醒
        renewed.nextChargeOn = date(2026, 11, 1)
        let plan = ReminderPlanner.standardReminders(items: [renewed], reminderDays: [7, 3, 1], now: now, calendar: cal)
        XCTAssertEqual(plan.count, 3)
    }

    func testSnoozeSuppressesStandardRemindersAndPlansTomorrow() {
        let now = date(2026, 9, 12, 10, 0)
        let snoozed = item(charge: date(2026, 10, 1), snoozedForChargeOn: date(2026, 10, 1))
        XCTAssertTrue(ReminderPlanner.standardReminders(items: [snoozed], reminderDays: [7, 3, 1], now: now, calendar: cal).isEmpty)

        guard let snooze = ReminderPlanner.snoozeReminder(for: snoozed, now: now, calendar: cal) else {
            return XCTFail("刚请求的 snooze 应可排程")
        }
        XCTAssertEqual(snooze.fireAt.timeIntervalSince(now), 86_400, accuracy: 60)
        XCTAssertEqual(snooze.title, "续吗？")
    }

    func testSnoozeUsesPersistedRequestTimeAndDoesNotReArm() {
        let now = date(2026, 9, 13, 9, 0)
        // 昨天 15:00 请求的 snooze → 今天 15:00 触发，重启后不得顺延到明天
        let requested = item(
            charge: date(2026, 10, 1),
            snoozedForChargeOn: date(2026, 10, 1),
            snoozeRequestedAt: date(2026, 9, 12, 15, 0)
        )
        let snooze = ReminderPlanner.snoozeReminder(for: requested, now: now, calendar: cal)
        XCTAssertEqual(snooze?.fireAt, date(2026, 9, 13, 15, 0))

        // 早已过期（超过 1 天未打开）→ 不补发
        let stale = item(
            charge: date(2026, 10, 1),
            snoozedForChargeOn: date(2026, 10, 1),
            snoozeRequestedAt: date(2026, 9, 10, 15, 0)
        )
        XCTAssertNil(ReminderPlanner.snoozeReminder(for: stale, now: now, calendar: cal))
    }

    func testCancelPendingAndEndedItemsAreNotReminded() {
        let now = date(2026, 9, 12, 10, 0)
        let pending = item(charge: date(2026, 10, 1), status: .cancelPending)
        let ended = item(charge: date(2026, 10, 1), status: .ended)
        let plan = ReminderPlanner.standardReminders(items: [pending, ended], reminderDays: [7, 3, 1], now: now, calendar: cal)
        XCTAssertTrue(plan.isEmpty)
    }

    func testSentKeyMatchesReminder() {
        let now = date(2026, 9, 12, 10, 0)
        let item = item(charge: date(2026, 9, 22))
        let plan = ReminderPlanner.standardReminders(items: [item], reminderDays: [7, 3, 1], now: now, calendar: cal)
        for reminder in plan {
            let key = ReminderPlanner.sentKey(matching: reminder, items: [item])
            XCTAssertNotNil(key)
        }
    }

    // MARK: - 仓库（需求 7.1 / 11 / 12.1）

    private func makeStore() -> SubscriptionStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SubscriptionStore(filename: "test.json", directory: dir, calendar: cal)
    }

    func testStoreAddUpdateDeleteAndOrdering() {
        let store = makeStore()
        let a = item(name: "A", charge: date(2026, 10, 5))
        let b = item(name: "B", charge: date(2026, 10, 1))
        store.add(a)
        store.add(b)
        XCTAssertEqual(store.activeSorted.map(\.name), ["B", "A"], "按扣款日排序")
        XCTAssertEqual(store.nextItem?.name, "B")

        var edited = b
        edited.nextChargeOn = date(2026, 10, 20)
        store.update(edited)
        XCTAssertEqual(store.activeSorted.map(\.name), ["A", "B"])

        store.delete(a.id)
        XCTAssertEqual(store.activeSorted.count, 1)
    }

    func testFreeLimitIsThree() {
        let store = makeStore()
        for i in 0..<3 {
            XCTAssertTrue(store.canAddFree, "前 3 条可添加")
            store.add(item(name: "S\(i)", charge: date(2026, 10, 1 + i)))
        }
        XCTAssertFalse(store.canAddFree, "第 4 条应触发 Pro 提示")
        let before = store.items.count
        store.add(item(name: "S3", charge: date(2026, 10, 10)))
        XCTAssertEqual(store.items.count, before + 1, "仓库不硬拦，由 UI 层弹出 Pro 提示")
    }

    func testMarkRenewedStopsThisCycleReminders() {
        let store = makeStore()
        let sub = item(name: "A", charge: date(2026, 10, 1))
        store.add(sub)
        store.markRenewed(sub.id)
        let stored = store.item(with: sub.id)!
        XCTAssertEqual(stored.status, .active)
        XCTAssertTrue(stored.renewedThisCycle(calendar: cal))
    }

    func testCancelPendingBecomesEndedAfterChargeDatePasses() {
        let store = makeStore()
        let past = item(name: "P", charge: date(2026, 9, 11))
        let future = item(name: "F", charge: date(2026, 9, 12))
        store.add(past)
        store.add(future)
        store.markCancelPending(past.id)
        store.markCancelPending(future.id)
        XCTAssertEqual(store.item(with: past.id)?.status, .cancelPending)

        store.refreshStatuses(now: date(2026, 9, 12, 12, 0))
        XCTAssertEqual(store.item(with: past.id)?.status, .ended, "过扣款日的已取消订阅应结束")
        XCTAssertEqual(store.item(with: future.id)?.status, .cancelPending)
        XCTAssertFalse(store.activeSorted.contains { $0.id == past.id })
    }

    func testChargesThisMonthOnlyCountsActiveInCurrentMonth() {
        let store = makeStore()
        store.add(item(name: "本月", amount: 50, currency: .CNY, charge: date(2026, 9, 20)))
        store.add(item(name: "下月", amount: 50, currency: .CNY, charge: date(2026, 10, 1)))
        store.add(item(name: "已取消", amount: 50, currency: .CNY, charge: date(2026, 9, 25), status: .cancelPending))
        let charges = store.chargesThisMonth(now: date(2026, 9, 12, 12, 0))
        XCTAssertEqual(charges.map(\.name), ["本月"])
    }

    // MARK: - 汇率与折算（需求 8）

    func testFixedRatesConvertUSDToCNY() {
        XCTAssertEqual(ExchangeRates.convert(20, from: .USD, to: .CNY), 144)
        XCTAssertEqual(ExchangeRates.convert(144, from: .CNY, to: .USD), 20)
    }

    func testMonthlyEquivalentNormalizesCycles() {
        let yearly = item(amount: 299, currency: .CNY, cycle: .yearly, charge: date(2026, 10, 1))
        let monthly = NSDecimalNumber(decimal: ExchangeRates.rounded(yearly.monthlyEquivalent, in: .CNY)).intValue
        XCTAssertEqual(monthly, 25, "年付 299 ≈ 每月 25")

        let trial = item(amount: 0, currency: .CNY, cycle: .trial, charge: date(2026, 10, 1))
        XCTAssertEqual(trial.monthlyEquivalent, 0)
    }

    // MARK: - 月报（需求 6.6）

    func testMonthReportBuildsCountsTotalsAndSavings() {
        let now = date(2026, 9, 12, 12, 0)
        let items = [
            item(name: "Claude Pro", amount: 144, currency: .CNY, charge: date(2026, 9, 15), usageMark: 5),
            item(name: "Cursor Pro", amount: 20, currency: .USD, charge: date(2026, 9, 20), usageMark: 0),
            item(name: "下月到期", amount: 50, currency: .CNY, charge: date(2026, 10, 1), usageMark: 0),
            item(name: "已取消", amount: 50, currency: .CNY, charge: date(2026, 9, 25), status: .cancelPending),
        ]
        let report = MonthReportBuilder.build(items: items, mainCurrency: .CNY, now: now, calendar: cal)
        XCTAssertEqual(report.monthTitle, "2026年9月")
        XCTAssertEqual(report.count, 2)
        XCTAssertEqual(report.totalText, "¥288", "144 + 20×7.2 = 288")
        XCTAssertEqual(report.entries.count, 2)
        XCTAssertEqual(report.reviewEntries.map(\.name), ["Cursor Pro", "下月到期"], "建议复查覆盖全部生效中的低使用条目")
        XCTAssertEqual(report.reviewSavingsText, "¥194", "低使用条目按月折算 (144 + 50)")
    }

    // MARK: - 通知文案去重键

    func testSubscriptionCodableRoundTripKeepsDecisionFields() throws {
        let original = item(charge: date(2026, 10, 1), renewedForChargeOn: date(2026, 10, 1))
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([Subscription].self, from: data)
        XCTAssertEqual(decoded.first?.renewedThisCycle(calendar: cal), true)

        // 旧版本 JSON（无新字段）也能解码
        let legacy = """
        [{"id":"\(original.id.uuidString)","name":"Old","amount":20,"currency":"USD","cycle":"monthly","nextChargeOn":"2026-10-01T00:00:00Z","channel":"official","status":"active","notes":"","createdAt":"2026-09-01T00:00:00Z"}]
        """.data(using: .utf8)!
        let legacyDecoder = JSONDecoder()
        legacyDecoder.dateDecodingStrategy = .iso8601
        let legacyDecoded = try legacyDecoder.decode([Subscription].self, from: legacy)
        XCTAssertEqual(legacyDecoded.first?.name, "Old")
        XCTAssertNil(legacyDecoded.first?.renewedForChargeOn)
    }
}
