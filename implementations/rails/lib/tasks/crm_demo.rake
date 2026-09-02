# frozen_string_literal: true

namespace :crm do
  namespace :demo do
    desc "Create deterministic, related demo CRM data (COUNT=100 by default)"
    task seed: :environment do
      unless Rails.env.development? || ENV["ALLOW_DEMO_DATA"] == "1"
        abort "Demo data is restricted to development. Set ALLOW_DEMO_DATA=1 to override intentionally."
      end

      count = Integer(ENV.fetch("COUNT", "100"))
      report = Crm::DemoData.run!(count: count, progress: ->(message) { puts message })
      puts
      puts "Demo data ready:"
      report.each { |object_type, created| puts "  #{object_type.ljust(24)} #{created}" }
    end
  end
end
