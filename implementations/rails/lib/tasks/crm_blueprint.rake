# frozen_string_literal: true

require Rails.root.join("lib/crm/blueprint")
require Rails.root.join("lib/crm/blueprint/generator")

namespace :crm do
  namespace :blueprint do
    def crm_blueprint
      @crm_blueprint ||= Crm::Blueprint.new(Rails.root.join("../../specs/data-model.json"))
    end

    desc "Validate the shared CRM data-model blueprint"
    task validate: :environment do
      crm_blueprint.validate!
      puts "Blueprint #{crm_blueprint.data.fetch('version')} is valid (#{crm_blueprint.object_names.length} objects)."
    end

    desc "Generate the Rails manifest, models, and reviewed migrations"
    task generate: :environment do
      generator = Crm::Blueprint::Generator.new(blueprint: crm_blueprint)
      generator.generate!
      puts "Generated #{generator.outputs.length} deterministic blueprint files."
    end

    desc "Fail if generated Rails blueprint artifacts do not match the specification"
    task check: :environment do
      Crm::Blueprint::Generator.new(blueprint: crm_blueprint).check!
      puts "Generated blueprint artifacts match specs/data-model.json."
    end
  end
end
