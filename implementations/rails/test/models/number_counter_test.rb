# frozen_string_literal: true

require "test_helper"

class NumberCounterTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { NumberCounter.delete_all }
  teardown { NumberCounter.delete_all }

  test "allocates padded values atomically across connections" do
    values = Queue.new
    threads = 4.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          3.times { values << NumberCounter.allocate!(object_type: "ConcurrentExample", width: 6) }
        end
      end
    end
    threads.each(&:join)

    assert_equal (1..12).map { |number| number.to_s.rjust(6, "0") }, 12.times.map { values.pop }.sort
    assert_equal 13, NumberCounter.find("ConcurrentExample").next_value
  end

  test "display removes padding only from numeric identifiers" do
    assert_equal "42", NumberCounter.display("000042")
    assert_equal "0", NumberCounter.display("000000")
    assert_equal "DE10002345", NumberCounter.display("DE10002345")
  end

  test "raises before a generated value exceeds its storage length" do
    NumberCounter.create!(object_type: "Tiny", next_value: 10)

    assert_raises(RangeError) { NumberCounter.allocate!(object_type: "Tiny", width: 1) }
  end

  test "an imported alphanumeric identifier is preserved" do
    product = Product.new(product_number: "SAP-A1")
    product.validate

    assert_equal "SAP-A1", product.product_number
    assert_not NumberCounter.exists?(object_type: "Product")
  end
end
