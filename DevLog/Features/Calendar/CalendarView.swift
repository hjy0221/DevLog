import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DSColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        HStack {
                            monthButton(offset: -1, symbol: "chevron.left", label: "이전 달")
                            Spacer()
                            Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).year()))
                            .font(DSTypography.largeTitle)
                            .foregroundStyle(DSColor.textPrimary)
                            Spacer()
                            monthButton(offset: 1, symbol: "chevron.right", label: "다음 달")
                        }

                        SurfaceCard {
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 220)
                            } else if let error = viewModel.errorMessage {
                                ContentUnavailableView("로드 실패", systemImage: "exclamationmark.triangle", description: Text(error))
                            } else {
                                ActivityCalendarGrid(
                                    days: viewModel.days,
                                    selectedDate: viewModel.selectedDate,
                                    onSelect: viewModel.select
                                )
                            }
                        }

                        selectedSummary
                        DailyNoteSection(date: viewModel.selectedDate)
                            .id(Calendar.current.startOfDay(for: viewModel.selectedDate))
                        ForEach(viewModel.selectedDay?.summary?.activities ?? []) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(DSSpacing.md)
                }
            }
            .navigationTitle("Calendar")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var selectedSummary: some View {
        if let summary = viewModel.selectedDay?.summary {
            DailySummaryCard(summary: summary)
        } else {
            SurfaceCard {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("활동이 없는 날")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColor.textPrimary)

                    Text("이 날짜에는 기록된 commit, PR, issue가 없습니다.")
                        .font(DSTypography.callout)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func monthButton(offset: Int, symbol: String, label: String) -> some View {
        Button {
            Task { await viewModel.moveMonth(by: offset) }
        } label: {
            Image(systemName: symbol).frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
        .help(label)
        .disabled(viewModel.isLoading)
    }
}
