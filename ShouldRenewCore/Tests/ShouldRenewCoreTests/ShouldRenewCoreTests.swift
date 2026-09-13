import XCTest
@testable import ShouldRenewCore

/// xuma-prd-for-ai.md 验收与规则的单测覆盖
@MainActor
final class ShouldRenewCoreTests: XCTestCase {
    let cal = Calendar.current

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10, _ mi: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: mi))!
    }

    private func item(
        name: String = "Claude Pro",
        catalogId: String = "claude-pro",
        price: Decimal = 20,
        currency: Currency = .usd,
        cycle: Cycle = .monthly,
        channel: Channel = .website,
        purpose: Purpose = .chat,
        charge: Date,
        status: Status = .active
    ) -> Subscription {
        Subscription(
            catalogId: catalogId,
            name: name,
            price: price,
            currency: currency,
            cycle: cycle,
            channel: channel,
            purpose: purpose,
            nextChargeAt: charge,
            status: status
        )
    }

    private func makeStore() -> SubscriptionStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SubscriptionStore(filename: "test.json", directory: dir, calendar: cal)
    }

    // MARK: - 目录（§3 MVP catalog，逐项一致）

    func testCatalogMatchesPRDTable() {
        // PRD §3 原 10 项逐字保留
        let prdItems: [(String, String, Decimal, Currency, Purpose, Channel)] = [
            ("chatgpt-plus", "ChatGPT Plus", 20, .usd, .chat, .website),
            ("claude-pro", "Claude Pro", 20, .usd, .chat, .website),
            ("cursor-pro", "Cursor Pro", 20, .usd, .coding, .website),
            ("gemini-advanced", "Gemini Advanced", 19.99, .usd, .chat, .website),
            ("github-copilot", "GitHub Copilot", 10, .usd, .coding, .website),
            ("midjourney", "Midjourney", 10, .usd, .image, .website),
            ("perplexity-pro", "Perplexity Pro", 20, .usd, .search, .website),
            ("kimi-member", "Kimi 会员", 49, .cny, .chat, .wechat),
            ("tongyi", "通义会员", 49, .cny, .chat, .alipay),
            ("custom", "自定义", 0, .usd, .other, .website),
        ]
        for (id, name, price, currency, purpose, channel) in prdItems {
            let item = Catalog.item(id: id)
            XCTAssertNotNil(item, "缺少目录项 \(id)")
            XCTAssertEqual(item?.name, name)
            XCTAssertEqual(item?.defaultPrice, price)
            XCTAssertEqual(item?.currency, currency)
            XCTAssertEqual(item?.purpose, purpose)
            XCTAssertEqual(item?.defaultChannel, channel)
            XCTAssertEqual(item?.cycle, .monthly)
        }

        // 扩充的主流厂商套餐（覆盖去重 + 全部为 AI 工具）
        let expectedNewIDs = ["chatgpt-pro", "claude-max", "grok", "poe", "doubao", "ernie", "zhipu",
                              "windsurf-pro", "jetbrains-ai", "jimeng", "runway", "kling", "suno",
                              "elevenlabs", "notion-ai", "metaso"]
        for id in expectedNewIDs {
            XCTAssertNotNil(Catalog.item(id: id), "缺少扩充目录项 \(id)")
        }
        let ids = Catalog.items.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "目录 id 不得重复")
        XCTAssertEqual(ids.last, "custom", "自定义固定在最后")
    }

    func testCustomDraftHasEmptyName() {
        let draft = Catalog.makeDraft(Catalog.item(id: "custom")!)
        XCTAssertEqual(draft.name, "")
        XCTAssertEqual(draft.catalogId, "custom")
        let claude = Catalog.makeDraft(Catalog.item(id: "claude-pro")!)
        XCTAssertEqual(claude.name, "Claude Pro")
        XCTAssertEqual(claude.price, 20)
    }

    // MARK: - 取消指南（§5.3 四渠道四步，文案逐字）

    func testGuideStepsExactPerChannel() {
        let apple = CancelGuide.steps(channel: .apple).map(\.title)
        XCTAssertEqual(apple, [
            "打开设置 → Apple ID → 订阅",
            "找到对应项目",
            "点取消订阅，确认不再续期",
            "回到续吗，点「我已取消」",
        ])
        XCTAssertTrue(CancelGuide.steps(channel: .wechat).contains { $0.title.contains("自动续费") })
        XCTAssertTrue(CancelGuide.steps(channel: .alipay).contains { $0.title.contains("免密支付 / 自动续费") })
        XCTAssertTrue(CancelGuide.steps(channel: .website).contains { $0.title.contains("Auto-renew / Cancel plan") })
        for channel in Channel.allCases {
            XCTAssertEqual(CancelGuide.steps(channel: channel).count, 4, "\(channel) 应为 4 步")
        }
    }

    // MARK: - 提醒（§6，验收 A2）

    func testReminderIdentifierBodyAndSkipPast() {
        let now = date(2026, 9, 13, 10, 0)
        // +3 天：7 天档与 3 天档已过（09:30），只剩 1 天档
        let item = item(charge: date(2026, 9, 16))
        let plan = ReminderPlanner.reminders(items: [item], now: now, calendar: cal)
        XCTAssertEqual(plan.map(\.identifier), ["renew.\(item.id.uuidString).1"])
        XCTAssertEqual(plan[0].title, "续吗")
        XCTAssertEqual(plan[0].body, "Claude Pro 1 天后扣 $20，续吗？")

        let comps = cal.dateComponents([.hour, .minute], from: plan[0].fireAt)
        XCTAssertEqual(comps.hour, 9)
        XCTAssertEqual(comps.minute, 30)
    }

    func testReminderFullScheduleWhenFarOut() {
        let now = date(2026, 9, 13, 8, 0)
        let item = item(charge: date(2026, 10, 1))
        let plan = ReminderPlanner.reminders(items: [item], now: now, calendar: cal)
        XCTAssertEqual(plan.map(\.identifier), [
            "renew.\(item.id.uuidString).7",
            "renew.\(item.id.uuidString).3",
            "renew.\(item.id.uuidString).1",
        ])
    }

    func testNonActiveItemsAreNotReminded() {
        let now = date(2026, 9, 13, 10, 0)
        let items = [
            item(name: "A", charge: date(2026, 10, 1), status: .decidedRenew),
            item(name: "B", charge: date(2026, 10, 1), status: .canceled),
            item(name: "C", charge: date(2026, 10, 1), status: .snoozed),
        ]
        XCTAssertTrue(ReminderPlanner.reminders(items: items, now: now, calendar: cal).isEmpty)
    }

    // MARK: - 决策与生命周期（§3 规则，验收 A3/A4）

    func testUpcomingDecisionWindowAndOrder() {
        let store = makeStore()
        store.add(item(name: "近", charge: date(2026, 9, 15)))
        store.add(item(name: "远", charge: date(2026, 10, 1)))
        store.add(item(name: "太远", charge: date(2026, 12, 1)))
        XCTAssertEqual(store.upcomingDecision(now: date(2026, 9, 13))?.name, "近")

        // 15 天外不进入决策卡
        let store2 = makeStore()
        store2.add(item(name: "远", charge: date(2026, 9, 29)))
        XCTAssertNil(store2.upcomingDecision(now: date(2026, 9, 13)))
    }

    func testRenewMarksDecidedRenewThenRollsForward() {
        let store = makeStore()
        let sub = item(charge: date(2026, 10, 1))
        store.add(sub)
        store.markRenewed(sub.id)
        XCTAssertEqual(store.item(with: sub.id)?.status, .decidedRenew)
        XCTAssertNil(store.upcomingDecision(now: date(2026, 9, 20)), "decidedRenew 不再进决策卡")

        // 扣款日过后滚动一个月并转回 active
        store.refresh(now: date(2026, 10, 2, 12, 0))
        let rolled = store.item(with: sub.id)!
        XCTAssertEqual(rolled.status, .active)
        XCTAssertEqual(cal.startOfDay(for: rolled.nextChargeAt), cal.startOfDay(for: date(2026, 11, 1)))
    }

    func testYearlyRollForwardMultipleCycles() {
        let store = makeStore()
        let sub = item(price: 299, currency: .cny, cycle: .yearly, charge: date(2024, 1, 1))
        store.add(sub)
        store.markRenewed(sub.id)
        store.refresh(now: date(2026, 9, 13, 12, 0))
        let rolled = store.item(with: sub.id)!
        XCTAssertEqual(rolled.status, .active)
        XCTAssertEqual(cal.startOfDay(for: rolled.nextChargeAt), cal.startOfDay(for: date(2027, 1, 1)))
    }

    func testCancelHidesFromTodayAndCaps() {
        let store = makeStore()
        let a = item(name: "A", charge: date(2026, 9, 15))
        let b = item(name: "B", charge: date(2026, 9, 20))
        store.add(a)
        store.add(b)
        store.markCanceled(a.id)
        XCTAssertEqual(store.item(with: a.id)?.status, .canceled)
        XCTAssertEqual(store.upcomingDecision(now: date(2026, 9, 13))?.name, "B", "canceled 不进决策卡，候选顺延到 B")
        XCTAssertTrue(store.canAdd, "canceled 不计入 3 条上限")
    }

    func testFreeCapCountsNonCanceledOnly() {
        let store = makeStore()
        for i in 0..<3 {
            store.add(item(name: "S\(i)", charge: date(2026, 10, 1 + i)))
        }
        XCTAssertFalse(store.canAdd, "满 3 条不可再加")
        store.markCanceled(store.items[0].id)
        XCTAssertTrue(store.canAdd, "取消一条后腾出名额")
    }

    func testUndoRenewAndSnoozeReturnToActive() {
        let store = makeStore()
        let sub = item(charge: date(2026, 9, 20))
        store.add(sub)

        store.markRenewed(sub.id)
        XCTAssertEqual(store.item(with: sub.id)?.status, .decidedRenew)
        store.markActive(sub.id)
        XCTAssertEqual(store.item(with: sub.id)?.status, .active, "撤销续费应回到 active")
        XCTAssertEqual(store.upcomingDecision(now: date(2026, 9, 13))?.id, sub.id, "撤销后重新进决策卡")

        store.markSnoozed(sub.id, now: date(2026, 9, 13, 15, 0))
        store.markActive(sub.id)
        let undone = store.item(with: sub.id)!
        XCTAssertEqual(undone.status, .active)
        XCTAssertNil(undone.snoozeUntil, "撤销 snooze 应清空 snoozeUntil")
    }

    func testSnoozeLifecycle() {
        let store = makeStore()
        let sub = item(charge: date(2026, 9, 20))
        store.add(sub)
        let now = date(2026, 9, 13, 15, 0)
        store.markSnoozed(sub.id, now: now)
        let snoozed = store.item(with: sub.id)!
        XCTAssertEqual(snoozed.status, .snoozed)
        XCTAssertEqual(cal.startOfDay(for: snoozed.snoozeUntil!), cal.startOfDay(for: date(2026, 9, 14, 15, 0)))
        XCTAssertNil(store.upcomingDecision(now: now), "snoozed 期间不进决策卡")

        store.refresh(now: date(2026, 9, 14, 16, 0))
        XCTAssertEqual(store.item(with: sub.id)?.status, .active, "snoozeUntil 过后转回 active")
    }

    func testOverlapHintSamePurposeOnly() {
        let store = makeStore()
        store.add(item(name: "Cursor Pro", catalogId: "cursor-pro", purpose: .coding, charge: date(2026, 10, 1)))
        store.add(item(name: "GitHub Copilot", catalogId: "github-copilot", purpose: .coding, charge: date(2026, 10, 2)))
        store.add(item(name: "Claude Pro", catalogId: "claude-pro", purpose: .chat, charge: date(2026, 10, 3)))
        let hint = store.overlapHint()
        XCTAssertEqual(hint?.0.name, "Cursor Pro")
        XCTAssertEqual(hint?.1.name, "GitHub Copilot")
        XCTAssertEqual(hint?.2, .coding)

        let single = makeStore()
        single.add(item(name: "A", purpose: .coding, charge: date(2026, 10, 1)))
        single.add(item(name: "B", purpose: .chat, charge: date(2026, 10, 2)))
        XCTAssertNil(single.overlapHint())
    }

    // MARK: - 旧版数据迁移

    func testLegacyJSONMigrates() throws {
        let store = makeStore()
        let legacy = """
        [
          {"id":"11111111-1111-1111-1111-111111111111","name":"Claude Pro","templateKey":"claude_pro",
           "emoji":"🌟","amount":20,"currency":"USD","cycle":"monthly","nextChargeOn":"2026-10-01T00:00:00Z",
           "channel":"official","purpose":"writing","usageMark":3,"status":"active","notes":"",
           "createdAt":"2026-09-01T00:00:00Z","renewedForChargeOn":"2026-10-01T00:00:00Z"},
          {"id":"22222222-2222-2222-2222-222222222222","name":"通义会员","templateKey":"qwen",
           "emoji":"🦉","amount":49,"currency":"CNY","cycle":"monthly","nextChargeOn":"2026-10-05T00:00:00Z",
           "channel":"alipay","purpose":"writing","usageMark":null,"status":"cancelPending","notes":""},
          {"id":"33333333-3333-3333-3333-333333333333","name":"Mystery","templateKey":null,
           "amount":9,"currency":"SGD","cycle":"quarterly","nextChargeOn":"2026-11-01T00:00:00Z",
           "channel":"google","purpose":"video","usageMark":null,"status":"active","notes":""}
        ]
        """.data(using: .utf8)!

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try legacy.write(to: dir.appendingPathComponent("test.json"))
        let migrated = SubscriptionStore(filename: "test.json", directory: dir, calendar: cal)

        let claude = migrated.item(with: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
        XCTAssertEqual(claude?.status, .decidedRenew, "旧 renewedForChargeOn → decidedRenew")
        XCTAssertEqual(claude?.catalogId, "claude-pro")
        XCTAssertEqual(claude?.purpose, .chat, "writing → chat")
        XCTAssertEqual(claude?.channel, .website, "official → website")

        let tongyi = migrated.item(with: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)
        XCTAssertEqual(tongyi?.status, .canceled, "cancelPending → canceled")
        XCTAssertEqual(tongyi?.catalogId, "tongyi", "qwen → tongyi")

        let mystery = migrated.item(with: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!)
        XCTAssertEqual(mystery?.currency, .usd, "SGD → usd")
        XCTAssertEqual(mystery?.channel, .website, "google → website")
        XCTAssertEqual(mystery?.purpose, .image, "video → image")
        XCTAssertEqual(mystery?.catalogId, "custom")
    }
}
