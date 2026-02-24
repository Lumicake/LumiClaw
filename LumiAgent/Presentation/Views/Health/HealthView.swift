//
//  HealthView.swift
//  LumiAgent
//
//  Apple Health panel — metric cards, mini-charts, and per-category AI analysis.
//

import SwiftUI

// MARK: - Health Category

enum HealthCategory: String, CaseIterable, Identifiable {
    case activity  = "Activity"
    case heart     = "Heart"
    case body      = "Body"
    case sleep     = "Sleep"
    case workouts  = "Workouts"
    case vitals    = "Vitals"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .activity: return "figure.walk"
        case .heart:    return "heart.fill"
        case .body:     return "scalemass.fill"
        case .sleep:    return "bed.double.fill"
        case .workouts: return "dumbbell.fill"
        case .vitals:   return "waveform.path.ecg"
        }
    }

    var color: Color {
        switch self {
        case .activity: return .green
        case .heart:    return .red
        case .body:     return .blue
        case .sleep:    return .indigo
        case .workouts: return .orange
        case .vitals:   return .teal
        }
    }
}

#if os(macOS)
import HealthKit

// MARK: - Health Metric

struct HealthMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var date: Date = Date()
    var weeklyData: [(label: String, value: Double)] = []
}

// MARK: - HealthKit Manager

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var isAvailable: Bool
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var error: String?

    @Published var activityMetrics: [HealthMetric] = []
    @Published var heartMetrics: [HealthMetric] = []
    @Published var bodyMetrics: [HealthMetric] = []
    @Published var sleepMetrics: [HealthMetric] = []
    @Published var workoutMetrics: [HealthMetric] = []
    @Published var vitalsMetrics: [HealthMetric] = []

    @Published var analysisResults: [HealthCategory: String] = [:]
    @Published var analyzingCategory: HealthCategory?

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .appleExerciseTime,
            .flightsClimbed, .distanceWalkingRunning,
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .oxygenSaturation, .vo2Max,
            .bodyMass, .bodyMassIndex, .height,
            .respiratoryRate, .bloodPressureSystolic, .bloodPressureDiastolic
        ]
        let categoryIds: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis, .mindfulSession, .appleStandHour
        ]
        for id in quantityIds {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        for id in categoryIds {
            if let t = HKCategoryType.categoryType(forIdentifier: id) { types.insert(t) }
        }
        types.insert(HKObjectType.workoutType())
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else {
            error = "Apple Health is not available on this device."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await loadAllMetrics()
        } catch {
            self.error = "Authorization failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Load All

    func loadAllMetrics() async {
        guard isAvailable else { return }
        isLoading = true
        error = nil
        async let a = loadActivityMetrics()
        async let h = loadHeartMetrics()
        async let b = loadBodyMetrics()
        async let s = loadSleepMetrics()
        async let w = loadWorkoutMetrics()
        async let v = loadVitalsMetrics()
        let (am, hm, bm, sm, wm, vm) = await (a, h, b, s, w, v)
        activityMetrics = am
        heartMetrics    = hm
        bodyMetrics     = bm
        sleepMetrics    = sm
        workoutMetrics  = wm
        vitalsMetrics   = vm
        isLoading = false
        isAuthorized = true
    }

    func metricsForCategory(_ category: HealthCategory) -> [HealthMetric] {
        switch category {
        case .activity: return activityMetrics
        case .heart:    return heartMetrics
        case .body:     return bodyMetrics
        case .sleep:    return sleepMetrics
        case .workouts: return workoutMetrics
        case .vitals:   return vitalsMetrics
        }
    }

    // MARK: - Activity

    private func loadActivityMetrics() async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        if let steps = await fetchDailySum(.stepCount, unit: .count()) {
            let weekly = await fetchWeeklySum(.stepCount, unit: .count())
            metrics.append(HealthMetric(name: "Steps", value: "\(Int(steps))", unit: "steps",
                                        icon: "figure.walk", color: .green, weeklyData: weekly))
        }
        if let energy = await fetchDailySum(.activeEnergyBurned, unit: .kilocalorie()) {
            let weekly = await fetchWeeklySum(.activeEnergyBurned, unit: .kilocalorie())
            metrics.append(HealthMetric(name: "Active Energy", value: "\(Int(energy))", unit: "kcal",
                                        icon: "flame.fill", color: .orange, weeklyData: weekly))
        }
        if let exercise = await fetchDailySum(.appleExerciseTime, unit: .minute()) {
            metrics.append(HealthMetric(name: "Exercise", value: "\(Int(exercise))", unit: "min",
                                        icon: "timer", color: .yellow))
        }
        if let flights = await fetchDailySum(.flightsClimbed, unit: .count()) {
            metrics.append(HealthMetric(name: "Floors Climbed", value: "\(Int(flights))", unit: "floors",
                                        icon: "arrow.up.right", color: .mint))
        }
        if let distance = await fetchDailySum(.distanceWalkingRunning, unit: .mile()) {
            metrics.append(HealthMetric(name: "Distance", value: String(format: "%.1f", distance), unit: "mi",
                                        icon: "map.fill", color: .teal))
        }
        return metrics
    }

    // MARK: - Heart

    private func loadHeartMetrics() async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let bpmUnit = HKUnit(from: "count/min")
        if let hr = await fetchLatest(.heartRate, unit: bpmUnit) {
            let weekly = await fetchWeeklyAvg(.heartRate, unit: bpmUnit)
            metrics.append(HealthMetric(name: "Heart Rate", value: "\(Int(hr))", unit: "bpm",
                                        icon: "heart.fill", color: .red, weeklyData: weekly))
        }
        if let rhr = await fetchLatest(.restingHeartRate, unit: bpmUnit) {
            metrics.append(HealthMetric(name: "Resting HR", value: "\(Int(rhr))", unit: "bpm",
                                        icon: "heart", color: .pink))
        }
        if let hrv = await fetchLatest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) {
            metrics.append(HealthMetric(name: "HRV", value: String(format: "%.0f", hrv), unit: "ms",
                                        icon: "waveform.path.ecg.rectangle.fill", color: .purple))
        }
        if let spo2 = await fetchLatest(.oxygenSaturation, unit: .percent()) {
            metrics.append(HealthMetric(name: "Blood Oxygen", value: String(format: "%.0f", spo2 * 100), unit: "%",
                                        icon: "drop.fill", color: .blue))
        }
        if let vo2 = await fetchLatest(.vo2Max, unit: HKUnit(from: "ml/kg·min")) {
            metrics.append(HealthMetric(name: "VO₂ Max", value: String(format: "%.1f", vo2), unit: "mL/kg/min",
                                        icon: "lungs.fill", color: .cyan))
        }
        return metrics
    }

    // MARK: - Body

    private func loadBodyMetrics() async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        if let weight = await fetchLatest(.bodyMass, unit: .pound()) {
            let weekly = await fetchWeeklyAvg(.bodyMass, unit: .pound())
            metrics.append(HealthMetric(name: "Weight", value: String(format: "%.1f", weight), unit: "lbs",
                                        icon: "scalemass.fill", color: .blue, weeklyData: weekly))
        }
        if let bmi = await fetchLatest(.bodyMassIndex, unit: .count()) {
            metrics.append(HealthMetric(name: "BMI", value: String(format: "%.1f", bmi), unit: "",
                                        icon: "person.crop.rectangle.fill", color: .indigo))
        }
        if let height = await fetchLatest(.height, unit: .foot()) {
            let feet = Int(height)
            let inches = Int((height - Double(feet)) * 12)
            metrics.append(HealthMetric(name: "Height", value: "\(feet)'\(inches)\"", unit: "",
                                        icon: "ruler.fill", color: .gray))
        }
        return metrics
    }

    // MARK: - Sleep

    private func loadSleepMetrics() async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let (inBed, asleep, deep, rem) = await fetchSleepMinutes()
        func fmt(_ minutes: Double) -> String {
            let h = Int(minutes / 60), m = Int(minutes) % 60
            return h > 0 ? "\(h)h \(m)m" : "\(m)m"
        }
        if inBed > 0 {
            metrics.append(HealthMetric(name: "Time in Bed", value: fmt(inBed), unit: "",
                                        icon: "bed.double.fill", color: .indigo))
        }
        if asleep > 0 {
            metrics.append(HealthMetric(name: "Sleep", value: fmt(asleep), unit: "",
                                        icon: "moon.zzz.fill", color: .purple))
        }
        if deep > 0 {
            metrics.append(HealthMetric(name: "Deep Sleep", value: fmt(deep), unit: "",
                                        icon: "moon.fill", color: .blue))
        }
        if rem > 0 {
            metrics.append(HealthMetric(name: "REM Sleep", value: fmt(rem), unit: "",
                                        icon: "sparkles", color: .cyan))
        }
        let mindful = await fetchMindfulMinutes()
        if mindful > 0 {
            metrics.append(HealthMetric(name: "Mindful (7d)", value: "\(Int(mindful))", unit: "min",
                                        icon: "brain.head.profile", color: .mint))
        }
        return metrics
    }

    // MARK: - Workouts

    private func loadWorkoutMetrics() async -> [HealthMetric] {
        let workouts = await fetchRecentWorkouts(limit: 10)
        return workouts.map { w in
            let duration = Int(w.duration / 60)
            let energy   = w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            return HealthMetric(
                name: w.workoutActivityType.displayName,
                value: "\(duration) min",
                unit: energy > 0 ? "· \(Int(energy)) kcal" : "",
                icon: w.workoutActivityType.sfSymbol,
                color: .orange,
                date: w.startDate
            )
        }
    }

    // MARK: - Vitals

    private func loadVitalsMetrics() async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let bpmUnit = HKUnit(from: "count/min")
        if let rr = await fetchLatest(.respiratoryRate, unit: bpmUnit) {
            metrics.append(HealthMetric(name: "Respiratory Rate", value: "\(Int(rr))", unit: "breaths/min",
                                        icon: "lungs.fill", color: .teal))
        }
        if let sys = await fetchLatest(.bloodPressureSystolic, unit: .millimeterOfMercury()),
           let dia = await fetchLatest(.bloodPressureDiastolic, unit: .millimeterOfMercury()) {
            metrics.append(HealthMetric(name: "Blood Pressure", value: "\(Int(sys))/\(Int(dia))", unit: "mmHg",
                                        icon: "heart.text.square.fill", color: .red))
        }
        return metrics
    }

    // MARK: - HK Helpers

    private func fetchDailySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let qType = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let pred  = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: qType, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func fetchLatest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let qType = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: qType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func fetchWeeklySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> [(label: String, value: Double)] {
        guard let qType = HKQuantityType.quantityType(forIdentifier: id) else { return [] }
        let calendar = Calendar.current
        var results: [(String, Double)] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: day)
            let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? day
            let pred  = HKQuery.predicateForSamples(withStart: start, end: end)
            let label = offset == 0 ? "Today" : calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            let value: Double = await withCheckedContinuation { cont in
                let q = HKStatisticsQuery(quantityType: qType, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                    cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
                }
                store.execute(q)
            }
            results.append((label, value))
        }
        return results
    }

    private func fetchWeeklyAvg(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> [(label: String, value: Double)] {
        guard let qType = HKQuantityType.quantityType(forIdentifier: id) else { return [] }
        let calendar = Calendar.current
        var results: [(String, Double)] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: day)
            let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? day
            let pred  = HKQuery.predicateForSamples(withStart: start, end: end)
            let label = offset == 0 ? "Today" : calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            let value: Double = await withCheckedContinuation { cont in
                let q = HKStatisticsQuery(quantityType: qType, quantitySamplePredicate: pred, options: .discreteAverage) { _, stats, _ in
                    cont.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit) ?? 0)
                }
                store.execute(q)
            }
            results.append((label, value))
        }
        return results
    }

    private func fetchSleepMinutes() async -> (inBed: Double, asleep: Double, deep: Double, rem: Double) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, 0, 0, 0)
        }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let pred = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: sleepType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, s, _ in
                cont.resume(returning: (s as? [HKCategorySample]) ?? [])
            }
            store.execute(q)
        }
        var inBed = 0.0, asleep = 0.0, deep = 0.0, rem = 0.0
        for sample in samples {
            let mins = sample.endDate.timeIntervalSince(sample.startDate) / 60
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBed += mins
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += mins; asleep += mins
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += mins; asleep += mins
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                asleep += mins
            default:
                // Legacy "asleep" value (1) from pre-iOS 16 data
                if sample.value == 1 { asleep += mins }
            }
        }
        return (inBed, asleep, deep, rem)
    }

    private func fetchMindfulMinutes() async -> Double {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return 0 }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let pred = HKQuery.predicateForSamples(withStart: weekAgo, end: Date())
        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: mindfulType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, s, _ in
                cont.resume(returning: (s as? [HKCategorySample]) ?? [])
            }
            store.execute(q)
        }
        return samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60 }
    }

    private func fetchRecentWorkouts(limit: Int) async -> [HKWorkout] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: limit, sortDescriptors: [sort]) { _, s, _ in
                cont.resume(returning: (s as? [HKWorkout]) ?? [])
            }
            store.execute(q)
        }
    }

    // MARK: - AI Analysis

    func analyzeCategory(_ category: HealthCategory, agent: Agent?) async {
        analyzingCategory = category
        defer { analyzingCategory = nil }

        let metrics = metricsForCategory(category)
        guard !metrics.isEmpty else {
            analysisResults[category] = "No health data available for \(category.rawValue). Connect your iPhone or Apple Watch to sync data."
            return
        }

        let dataLines = metrics.map { m -> String in
            let unitStr = m.unit.isEmpty ? "" : " \(m.unit)"
            return "  • \(m.name): \(m.value)\(unitStr)"
        }.joined(separator: "\n")

        let weeklyContext: String = {
            let withWeekly = metrics.filter { !$0.weeklyData.isEmpty }
            guard !withWeekly.isEmpty else { return "" }
            let lines = withWeekly.map { m -> String in
                let pts = m.weeklyData.map { "\($0.label): \(Int($0.value))" }.joined(separator: ", ")
                return "  • \(m.name) (7-day): \(pts)"
            }.joined(separator: "\n")
            return "\n\nWeekly trends:\n\(lines)"
        }()

        let prompt = """
        You are a knowledgeable health and wellness coach. Analyze the following health data and provide personalized, actionable feedback.

        Category: \(category.rawValue)
        Date: \(Date().formatted(date: .long, time: .omitted))

        Today's metrics:
        \(dataLines)\(weeklyContext)

        Please provide:
        1. A brief summary of what these numbers indicate
        2. What's going well
        3. Specific, actionable improvements (not generic advice)
        4. Any patterns worth noting from the weekly trends
        5. One concrete goal to focus on this week

        Keep it concise (3–4 paragraphs), encouraging, and practical. Always remind the user to consult a healthcare professional for medical concerns.
        """

        let repo = AIProviderRepository()
        let provider: AIProvider
        let model: String

        if let agent {
            provider = agent.configuration.provider
            model    = agent.configuration.model
        } else if (try? repo.getAPIKey(for: .openai)).flatMap({ $0.isEmpty ? nil : $0 }) != nil {
            provider = .openai
            model    = "gpt-4o"
        } else if (try? repo.getAPIKey(for: .anthropic)).flatMap({ $0.isEmpty ? nil : $0 }) != nil {
            provider = .anthropic
            model    = "claude-sonnet-4-6"
        } else if (try? repo.getAPIKey(for: .gemini)).flatMap({ $0.isEmpty ? nil : $0 }) != nil {
            provider = .gemini
            model    = "gemini-3.1-pro"
        } else {
            provider = .ollama
            model    = "llama3.2:latest"
        }

        do {
            let response = try await repo.sendMessage(
                provider: provider, model: model,
                messages: [AIMessage(role: .user, content: prompt)],
                systemPrompt: "You are a health and wellness coach. Provide personalized, evidence-based insights."
            )
            analysisResults[category] = response.content ?? "No analysis generated."
        } catch {
            analysisResults[category] = "Analysis failed: \(error.localizedDescription)\n\nCheck your AI provider settings."
        }
    }
}

// MARK: - HKWorkoutActivityType Extensions

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:          return "Running"
        case .walking:          return "Walking"
        case .cycling:          return "Cycling"
        case .swimming:         return "Swimming"
        case .yoga:             return "Yoga"
        case .hiking:           return "Hiking"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
                                return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .pilates:          return "Pilates"
        case .dance:            return "Dance"
        case .soccer:           return "Soccer"
        case .basketball:       return "Basketball"
        case .tennis:           return "Tennis"
        case .rowing:           return "Rowing"
        case .elliptical:       return "Elliptical"
        case .stairClimbing:    return "Stair Climbing"
        case .crossTraining:    return "Cross Training"
        default:                return "Workout"
        }
    }

    var sfSymbol: String {
        switch self {
        case .running:          return "figure.run"
        case .walking:          return "figure.walk"
        case .cycling:          return "figure.outdoor.cycle"
        case .swimming:         return "figure.pool.swim"
        case .yoga:             return "figure.mind.and.body"
        case .hiking:           return "figure.hiking"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
                                return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "bolt.fill"
        case .pilates:          return "figure.pilates"
        case .dance:            return "music.note"
        default:                return "figure.mixed.cardio"
        }
    }
}

// MARK: - Health List View (Sidebar content panel)

struct HealthListView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var hk = HealthKitManager.shared

    var body: some View {
        Group {
            if !hk.isAvailable {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Health Not Available")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Apple Health requires an Apple Silicon Mac running macOS 13 or later with iPhone or Apple Watch sync enabled.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(HealthCategory.allCases, selection: $appState.selectedHealthCategory) { category in
                    HealthCategoryRow(
                        category: category,
                        metricCount: hk.metricsForCategory(category).count,
                        isLoading: hk.isLoading
                    )
                    .tag(category)
                }
                .navigationTitle("Health")
                .toolbar {
                    ToolbarItemGroup {
                        if hk.isLoading {
                            ProgressView().scaleEffect(0.7)
                        }
                        Button {
                            Task {
                                if hk.isAuthorized {
                                    await hk.loadAllMetrics()
                                } else {
                                    await hk.requestAuthorization()
                                }
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(hk.isLoading)
                    }
                }
            }
        }
        .task {
            guard hk.isAvailable else { return }
            if hk.isAuthorized {
                await hk.loadAllMetrics()
            } else {
                await hk.requestAuthorization()
            }
        }
    }
}

private struct HealthCategoryRow: View {
    let category: HealthCategory
    let metricCount: Int
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.callout)
                    .foregroundStyle(category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.callout)
                    .fontWeight(.medium)
                Group {
                    if isLoading {
                        Text("Loading…")
                    } else if metricCount == 0 {
                        Text("No data")
                    } else {
                        Text("\(metricCount) metric\(metricCount == 1 ? "" : "s")")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Health Detail View

struct HealthDetailView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var hk = HealthKitManager.shared

    var body: some View {
        if let category = appState.selectedHealthCategory {
            let agent = appState.selectedAgentId.flatMap { id in appState.agents.first { $0.id == id } }
            HealthCategoryDetailView(
                category: category,
                metrics: hk.metricsForCategory(category),
                isLoading: hk.isLoading,
                analysis: hk.analysisResults[category],
                isAnalyzing: hk.analyzingCategory == category,
                onAnalyze: {
                    Task { await hk.analyzeCategory(category, agent: agent) }
                },
                onClearAnalysis: {
                    hk.analysisResults.removeValue(forKey: category)
                }
            )
        } else {
            EmptyDetailView(message: "Select a health category")
        }
    }
}

// MARK: - Category Detail View

struct HealthCategoryDetailView: View {
    let category: HealthCategory
    let metrics: [HealthMetric]
    let isLoading: Bool
    let analysis: String?
    let isAnalyzing: Bool
    let onAnalyze: () -> Void
    let onClearAnalysis: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(category.color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundStyle(category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(Date().formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onAnalyze) {
                        if isAnalyzing {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.75)
                                Text("Analyzing…")
                            }
                        } else {
                            Label(analysis == nil ? "AI Analysis" : "Re-analyze", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing || metrics.isEmpty)
                    .tint(category.color)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider()

                // ── Metrics grid ──────────────────────────────────────────
                Group {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading health data…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else if metrics.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No \(category.rawValue) data")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Make sure your iPhone or Apple Watch is syncing to Apple Health.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(metrics) { metric in
                                HealthMetricCard(metric: metric, category: category)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                    }
                }

                // ── AI Analysis ───────────────────────────────────────────
                if isAnalyzing {
                    HStack(spacing: 10) {
                        ProgressView().scaleEffect(0.75)
                        Text("Analyzing your \(category.rawValue.lowercased()) data with AI…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                if let analysis, !analysis.isEmpty {
                    Divider()
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(category.color)
                            Text("AI Health Insight")
                                .font(.headline)
                            Spacer()
                            Button {
                                onClearAnalysis()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(analysis)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(category.color.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(category.color.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Spacer(minLength: 28)
            }
        }
    }
}

// MARK: - Health Metric Card

struct HealthMetricCard: View {
    let metric: HealthMetric
    let category: HealthCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + date (for workouts)
            HStack {
                Image(systemName: metric.icon)
                    .font(.callout)
                    .foregroundStyle(metric.color)
                Spacer()
                if Calendar.current.isDateInToday(metric.date) == false && metric.date < Date().addingTimeInterval(-86400) {
                    Text(metric.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Value + unit
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(metric.value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(metric.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !metric.unit.isEmpty {
                        Text(metric.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Text(metric.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Mini bar chart
            if !metric.weeklyData.isEmpty {
                HealthMiniChart(data: metric.weeklyData, color: metric.color)
                    .frame(height: 30)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(metric.color.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Mini Bar Chart

struct HealthMiniChart: View {
    let data: [(label: String, value: Double)]
    let color: Color

    private var maxVal: Double { data.map(\.value).max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(data.indices, id: \.self) { i in
                let item = data[i]
                let ratio = maxVal > 0 ? item.value / maxVal : 0
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i == data.count - 1 ? color : color.opacity(0.35))
                    .frame(height: max(2, CGFloat(ratio) * 30))
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: data.map(\.value))
    }
}
#endif
