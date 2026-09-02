ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/crm_test_data"

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include CrmTestData

    teardown do
      Current.reset
      Crm::DomainEvents.reset! if defined?(Crm::DomainEvents)
    end

    # Add more helper methods to be used by all tests here...
  end
end
