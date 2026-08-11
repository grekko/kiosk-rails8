require "test_helper"

class MonthlyReportTest < ActiveSupport::TestCase
  test "reports start out as drafts" do
    report = MonthlyReport.create!(title: "January")

    assert_equal "draft", report.state
    assert_not report.completed?
    assert_nil report.completed_at
  end

  test "complete! marks the report as completed and reopen! undoes it" do
    report = MonthlyReport.create!(title: "January")

    report.complete!

    assert report.completed?
    assert_equal "completed", report.state
    assert_not_nil report.completed_at

    report.reopen!

    assert_not report.completed?
    assert_equal "draft", report.state
    assert_nil report.completed_at
  end

  test "completing twice keeps the first completion time" do
    report = MonthlyReport.create!(title: "January", completed_at: 2.days.ago)
    first_completion = report.completed_at

    report.complete!

    assert_in_delta first_completion, report.completed_at, 1.second
  end

  test "scopes separate drafts from completed reports" do
    draft = MonthlyReport.create!(title: "January")
    completed = MonthlyReport.create!(title: "February", completed_at: Time.current)

    assert_includes MonthlyReport.draft, draft
    assert_not_includes MonthlyReport.draft, completed
    assert_includes MonthlyReport.completed, completed
    assert_not_includes MonthlyReport.completed, draft
  end

  test "by_state filters by state and returns nothing for unknown states" do
    draft = MonthlyReport.create!(title: "January")
    completed = MonthlyReport.create!(title: "February", completed_at: Time.current)

    assert_includes MonthlyReport.by_state("draft"), draft
    assert_not_includes MonthlyReport.by_state("draft"), completed
    assert_includes MonthlyReport.by_state("completed"), completed
    assert_empty MonthlyReport.by_state("nonsense")
  end
end
