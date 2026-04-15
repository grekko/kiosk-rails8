require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "rounded_up_full_euro_in_cents rounds strictly to next full euro" do
    assert_equal 200, rounded_up_full_euro_in_cents(120)
    assert_equal 300, rounded_up_full_euro_in_cents(250)
    assert_equal 1100, rounded_up_full_euro_in_cents(1000)
  end

  test "rounded_up_full_euro_in_cents handles non-positive amounts" do
    assert_equal 0, rounded_up_full_euro_in_cents(0)
    assert_equal 0, rounded_up_full_euro_in_cents(-100)
  end

  test "round_up_delta_in_cents returns the additional amount" do
    assert_equal 80, round_up_delta_in_cents(120)
    assert_equal 50, round_up_delta_in_cents(250)
    assert_equal 100, round_up_delta_in_cents(1000)
  end
end
