# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class CreateCrmDomain < ActiveRecord::Migration[8.1]
  def change

    create_table :accounts, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :account_number, limit: 10, null: false
      t.string :name1, limit: 40, null: false
      t.string :name2, limit: 40
      t.string :street, limit: 60
      t.string :house_number, limit: 10
      t.string :postal_code, limit: 10
      t.string :city, limit: 40
      t.string :region, limit: 3
      t.string :country, limit: 3
      t.string :phone, limit: 30
      t.string :fax, limit: 30
      t.string :email, limit: 241
      t.string :website, limit: 132
      t.string :industry, limit: 10
      t.string :industry_description, limit: 100
      t.string :company_size, limit: 9
      t.decimal :annual_revenue, precision: 15, scale: 2
      t.string :currency, limit: 5
      t.string :parent_account_id, limit: 36
      t.string :owner_id, limit: 36, null: false
      t.text :description
      t.string :status, limit: 8, null: false, default: "Active"
    end

    create_table :contacts, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :contact_number, limit: 10, null: false
      t.string :title, limit: 30
      t.string :first_name, limit: 40, null: false
      t.string :last_name, limit: 40, null: false
      t.string :department, limit: 40
      t.string :position, limit: 40
      t.string :phone, limit: 30
      t.string :mobile, limit: 30
      t.string :email, limit: 241
      t.string :street, limit: 60
      t.string :house_number, limit: 10
      t.string :postal_code, limit: 10
      t.string :city, limit: 40
      t.string :country, limit: 3
      t.string :account_id, limit: 36
      t.string :owner_id, limit: 36, null: false
      t.text :description
      t.string :status, limit: 8, null: false, default: "Active"
    end

    create_table :contact_accounts, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :contact_id, limit: 36, null: false
      t.string :account_id, limit: 36, null: false
      t.string :role, limit: 50
      t.boolean :is_primary, null: false, default: false
    end

    create_table :leads, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :lead_number, limit: 10, null: false
      t.string :first_name, limit: 40, null: false
      t.string :last_name, limit: 40, null: false
      t.string :company, limit: 40
      t.string :position, limit: 40
      t.string :email, limit: 241
      t.string :phone, limit: 30
      t.string :mobile, limit: 30
      t.string :website, limit: 132
      t.string :source, limit: 14
      t.string :status, limit: 11, null: false, default: "New"
      t.integer :score, default: 0
      t.string :account_id, limit: 36
      t.string :contact_id, limit: 36
      t.string :converted_account_id, limit: 36
      t.string :converted_contact_id, limit: 36
      t.string :converted_opportunity_id, limit: 36
      t.datetime :converted_at
      t.string :owner_id, limit: 36, null: false
      t.text :description
    end

    create_table :opportunities, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :opportunity_number, limit: 10, null: false
      t.string :name, limit: 120, null: false
      t.string :account_id, limit: 36, null: false
      t.string :lead_id, limit: 36
      t.string :stage_id, limit: 36, null: false
      t.decimal :amount, precision: 15, scale: 2
      t.string :currency, limit: 5, null: false, default: "USD"
      t.integer :probability
      t.date :expected_close_date
      t.date :actual_close_date
      t.string :result, limit: 4, null: false, default: "Open"
      t.string :loss_reason, limit: 255
      t.string :owner_id, limit: 36, null: false
      t.text :description
    end

    create_table :opportunity_contacts, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :opportunity_id, limit: 36, null: false
      t.string :contact_id, limit: 36, null: false
      t.string :role, limit: 50
    end

    create_table :deal_rooms, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :deal_room_number, limit: 10, null: false
      t.string :name, limit: 120, null: false
      t.text :description
      t.string :opportunity_id, limit: 36, null: false
      t.string :status, limit: 6, null: false, default: "Active"
      t.string :owner_id, limit: 36, null: false
    end

    create_table :pipeline_stages, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 50, null: false
      t.integer :sort_order, null: false
      t.integer :default_probability
      t.boolean :is_closed, null: false, default: false
      t.boolean :is_won, null: false, default: false
      t.string :description, limit: 255
      t.boolean :active, null: false, default: true
    end

    create_table :quotations, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :quotation_number, limit: 10, null: false
      t.string :account_id, limit: 36, null: false
      t.string :contact_id, limit: 36
      t.string :opportunity_id, limit: 36
      t.string :status, limit: 8, null: false, default: "Draft"
      t.date :valid_from
      t.date :valid_to
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :currency, limit: 5, null: false, default: "USD"
      t.text :notes
      t.string :owner_id, limit: 36, null: false
    end

    create_table :sales_orders, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :order_number, limit: 10, null: false
      t.string :account_id, limit: 36, null: false
      t.string :contact_id, limit: 36
      t.string :opportunity_id, limit: 36
      t.string :quotation_id, limit: 36
      t.string :status, limit: 11, null: false, default: "Draft"
      t.date :order_date, null: false
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :currency, limit: 5, null: false, default: "USD"
      t.text :notes
      t.string :owner_id, limit: 36, null: false
    end

    create_table :invoices, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :invoice_number, limit: 10, null: false
      t.string :account_id, limit: 36, null: false
      t.string :contact_id, limit: 36
      t.string :sales_order_id, limit: 36
      t.string :status, limit: 14, null: false, default: "Draft"
      t.date :invoice_date, null: false
      t.date :due_date, null: false
      t.decimal :total_amount, precision: 15, scale: 2
      t.decimal :paid_amount, precision: 15, scale: 2, default: 0
      t.string :currency, limit: 5, null: false, default: "USD"
      t.text :notes
      t.string :owner_id, limit: 36, null: false
    end

    create_table :line_items, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :parent_type, limit: 11, null: false
      t.string :parent_id, limit: 36, null: false
      t.string :item_number, limit: 6, null: false
      t.string :product_id, limit: 36, null: false
      t.decimal :quantity, precision: 13, scale: 3, null: false, default: 1
      t.decimal :unit_price, precision: 11, scale: 2, null: false
      t.decimal :discount_percent, precision: 5, scale: 2, default: 0
      t.decimal :total_price, precision: 15, scale: 2
      t.string :unit_of_measure, limit: 3
      t.string :comment, limit: 40
      t.string :alternative_to, limit: 6
    end

    create_table :pricebook_entries, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :product_id, limit: 36, null: false
      t.string :account_id, limit: 36
      t.decimal :price, precision: 15, scale: 2
      t.string :currency, limit: 5
      t.decimal :quantity_from, precision: 13, scale: 3
      t.decimal :quantity_to, precision: 13, scale: 3
      t.decimal :discount_percent, precision: 5, scale: 2
      t.date :valid_from
      t.date :valid_to
      t.boolean :active, null: false, default: true
    end

    create_table :products, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :product_number, limit: 40, null: false
      t.string :name, limit: 40, null: false
      t.text :description
      t.string :product_group, limit: 9
      t.string :product_group_description, limit: 100
      t.string :unit_of_measure, limit: 3, null: false, default: "EA"
      t.decimal :base_price, precision: 13, scale: 2
      t.string :currency, limit: 5
      t.string :product_type, limit: 12, null: false, default: "Physical"
      t.string :status, limit: 12, null: false, default: "Active"
    end

    create_table :activities, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :activity_number, limit: 10, null: false
      t.string :type, limit: 7, null: false
      t.string :subject, limit: 255, null: false
      t.text :description
      t.string :status, limit: 11, null: false, default: "Planned"
      t.string :priority, limit: 6, default: "Medium"
      t.datetime :start_date
      t.datetime :end_date
      t.date :due_date
      t.datetime :completed_at
      t.integer :duration_minutes
      t.string :account_id, limit: 36
      t.string :contact_id, limit: 36
      t.string :lead_id, limit: 36
      t.string :opportunity_id, limit: 36
      t.string :ticket_id, limit: 36
      t.string :owner_id, limit: 36, null: false
      t.boolean :is_auto_logged, null: false, default: false
    end

    create_table :tickets, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :ticket_number, limit: 12, null: false
      t.string :subject, limit: 40, null: false
      t.text :description
      t.string :status_id, limit: 36, null: false
      t.string :priority, limit: 8, null: false, default: "Medium"
      t.string :category, limit: 50
      t.string :account_id, limit: 36, null: false
      t.string :contact_id, limit: 36
      t.string :asset_id, limit: 36
      t.string :service_contract_id, limit: 36
      t.string :sla_id, limit: 36
      t.string :assigned_to, limit: 36
      t.string :owner_id, limit: 36, null: false
      t.text :resolution
      t.datetime :sla_response_deadline
      t.datetime :sla_resolution_deadline
      t.datetime :first_response_at
      t.datetime :resolved_at
      t.datetime :closed_at
    end

    create_table :ticket_statuses, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 50, null: false
      t.integer :sort_order, null: false
      t.boolean :is_closed, null: false, default: false
      t.boolean :is_resolved, null: false, default: false
      t.string :description, limit: 255
      t.boolean :active, null: false, default: true
    end

    create_table :slas, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 100, null: false
      t.text :description
      t.decimal :response_time_hours, precision: 5, scale: 1, null: false
      t.decimal :resolution_time_hours, precision: 5, scale: 1, null: false
      t.json :applies_to_priorities
      t.boolean :business_hours_only, null: false, default: true
      t.boolean :active, null: false, default: true
    end

    create_table :knowledge_articles, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :article_number, limit: 10, null: false
      t.string :title, limit: 255, null: false
      t.text :content, null: false
      t.string :category, limit: 100
      t.string :status, limit: 9, null: false, default: "Draft"
      t.string :source, limit: 15, null: false, default: "Manual"
      t.string :author_id, limit: 36, null: false
      t.integer :views_count, null: false, default: 0
      t.integer :helpful_count, null: false, default: 0
      t.datetime :published_at
    end

    create_table :ticket_knowledge_articles, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :ticket_id, limit: 36, null: false
      t.string :article_id, limit: 36, null: false
      t.datetime :linked_at, null: false
      t.string :linked_by, limit: 36, null: false
    end

    create_table :service_contracts, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :contract_number, limit: 10, null: false
      t.string :name, limit: 120, null: false
      t.string :account_id, limit: 36, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, limit: 10, null: false, default: "Draft"
      t.text :entitlements
      t.string :sla_id, limit: 36
      t.string :owner_id, limit: 36, null: false
    end

    create_table :assets, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :asset_number, limit: 18, null: false
      t.string :name, limit: 40, null: false
      t.string :product_id, limit: 36, null: false
      t.string :account_id, limit: 36, null: false
      t.string :contact_id, limit: 36
      t.string :serial_number, limit: 18
      t.date :install_date
      t.date :warranty_end_date
      t.string :functional_location, limit: 30
      t.string :manufacturer, limit: 30
      t.string :model_number, limit: 20
      t.string :status, limit: 9, null: false, default: "Active"
      t.string :owner_id, limit: 36, null: false
    end

    create_table :documents, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 255, null: false
      t.string :file_path, limit: 500, null: false
      t.string :file_type, limit: 50
      t.integer :file_size
      t.string :parent_type, limit: 16, null: false
      t.string :parent_id, limit: 36, null: false
      t.string :uploaded_by, limit: 36, null: false
    end

    create_table :comments, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :parent_type, limit: 16, null: false
      t.string :parent_id, limit: 36, null: false
      t.text :content, null: false
      t.string :author_id, limit: 36, null: false
    end

    create_table :user_profiles, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :auth_uid, limit: 128
      t.string :email, limit: 241, null: false
      t.string :first_name, limit: 40, null: false
      t.string :last_name, limit: 40, null: false
      t.string :role_id, limit: 36, null: false
      t.string :team_id, limit: 36
      t.string :avatar_url, limit: 2048
      t.integer :xp_total, null: false, default: 0
      t.integer :level, null: false, default: 1
      t.string :level_name, limit: 50, null: false, default: "Rookie"
      t.integer :current_streak_days, null: false, default: 0
      t.integer :longest_streak_days, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.string :theme_preference, limit: 6, null: false, default: "System"
      t.json :notification_preferences
      t.string :language_preference, limit: 5, default: "en"
    end

    create_table :roles, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 50, null: false
      t.string :description, limit: 255
      t.boolean :is_system_role, null: false, default: false
      t.json :permissions, null: false
      t.json :ribbon_items, null: false
      t.json :visible_cards
      t.json :layout_config
      t.boolean :active, null: false, default: true
    end

    create_table :teams, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 100, null: false
      t.string :manager_id, limit: 36, null: false
      t.string :description, limit: 255
      t.boolean :active, null: false, default: true
    end

    create_table :notifications, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :type, limit: 18, null: false
      t.string :title, limit: 255, null: false
      t.string :message, limit: 500
      t.boolean :read, null: false, default: false
      t.string :link_type, limit: 50
      t.string :link_id, limit: 36
      t.boolean :send_email, null: false, default: false
      t.boolean :email_sent, null: false, default: false
    end

    create_table :dashboard_configs, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :name, limit: 100, null: false, default: "My Dashboard"
      t.boolean :is_default, null: false, default: true
      t.json :widgets, null: false
    end

    create_table :badges, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :name, limit: 100, null: false
      t.string :description, limit: 255, null: false
      t.string :icon_url, limit: 500
      t.string :category, limit: 13, null: false
      t.json :criteria, null: false
      t.boolean :is_custom, null: false, default: false
      t.boolean :active, null: false, default: true
    end

    create_table :user_badges, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :badge_id, limit: 36, null: false
      t.datetime :earned_at, null: false
    end

    create_table :challenges, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :title, limit: 255, null: false
      t.text :description, null: false
      t.integer :month, null: false
      t.integer :year, null: false
      t.string :target_metric, limit: 100, null: false
      t.decimal :target_value, precision: 10, scale: 2, null: false
      t.decimal :current_value, precision: 10, scale: 2, null: false, default: 0
      t.string :status, limit: 9, null: false, default: "Active"
      t.string :reward_badge_id, limit: 36
      t.integer :reward_xp, null: false, default: 0
      t.datetime :completed_at
    end

    create_table :streaks, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :activity_type, limit: 50, null: false
      t.integer :current_count, null: false, default: 0
      t.integer :longest_count, null: false, default: 0
      t.date :last_activity_date
    end

    create_table :personal_bests, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :user_id, limit: 36, null: false
      t.string :metric, limit: 100, null: false
      t.decimal :value, precision: 15, scale: 2, null: false
      t.datetime :achieved_at, null: false
      t.decimal :previous_value, precision: 15, scale: 2
      t.datetime :previous_achieved_at
    end

    create_table :audit_logs, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :object_type, limit: 50, null: false
      t.string :object_id, limit: 36, null: false
      t.string :action, limit: 6, null: false
      t.string :field_name, limit: 100
      t.text :old_value
      t.text :new_value
      t.string :user_id, limit: 36, null: false
      t.datetime :timestamp, null: false
      t.string :object_name, limit: 255
      t.string :summary, limit: 500
    end

    create_table :data_source_configs, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :object_type, limit: 50, null: false
      t.string :source_type, limit: 8, null: false, default: "Local"
      t.string :endpoint_url, limit: 500
      t.string :auth_type, limit: 9
      t.json :auth_config
      t.json :field_mapping
      t.boolean :active, null: false, default: true
    end

    create_table :ai_provider_configs, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :provider, limit: 9, null: false
      t.string :model, limit: 100, null: false
      t.string :api_key, limit: 500, null: false
      t.string :endpoint_url, limit: 500
      t.boolean :is_active, null: false, default: false
    end

    create_table :level_definitions, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.integer :level, null: false
      t.string :name, limit: 50, null: false
      t.integer :xp_threshold, null: false
      t.json :unlocks
      t.string :icon_url, limit: 500
    end

    create_table :xp_events, id: false do |t|
      t.string :id, limit: 36, null: false, primary_key: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.string :event_type, limit: 100, null: false
      t.string :description, limit: 255, null: false
      t.integer :xp_value, null: false
      t.boolean :active, null: false, default: true
    end

    add_check_constraint :accounts, "length(id) = 36", name: "chk_accounts_id_uuid"
    add_check_constraint :accounts, "length(created_by) = 36", name: "chk_accounts_created_by_uuid"
    add_index :accounts, [:created_by], name: "idx_accounts_created_by"
    add_check_constraint :accounts, "length(updated_by) = 36", name: "chk_accounts_updated_by_uuid"
    add_index :accounts, [:updated_by], name: "idx_accounts_updated_by"
    add_check_constraint :accounts, "length(account_number) <= 10", name: "chk_accounts_account_number_length"
    add_index :accounts, [:account_number], name: "idx_accounts_account_number", unique: true
    add_check_constraint :accounts, "length(name1) <= 40", name: "chk_accounts_name1_length"
    add_check_constraint :accounts, "length(name2) <= 40", name: "chk_accounts_name2_length"
    add_check_constraint :accounts, "length(street) <= 60", name: "chk_accounts_street_length"
    add_check_constraint :accounts, "length(house_number) <= 10", name: "chk_accounts_house_number_length"
    add_check_constraint :accounts, "length(postal_code) <= 10", name: "chk_accounts_postal_code_length"
    add_check_constraint :accounts, "length(city) <= 40", name: "chk_accounts_city_length"
    add_check_constraint :accounts, "length(region) <= 3", name: "chk_accounts_region_length"
    add_check_constraint :accounts, "length(country) <= 3", name: "chk_accounts_country_length"
    add_check_constraint :accounts, "length(phone) <= 30", name: "chk_accounts_phone_length"
    add_check_constraint :accounts, "length(fax) <= 30", name: "chk_accounts_fax_length"
    add_check_constraint :accounts, "length(email) <= 241", name: "chk_accounts_email_length"
    add_check_constraint :accounts, "length(website) <= 132", name: "chk_accounts_website_length"
    add_check_constraint :accounts, "length(industry) <= 10", name: "chk_accounts_industry_length"
    add_check_constraint :accounts, "length(industry_description) <= 100", name: "chk_accounts_industry_description_length"
    add_check_constraint :accounts, "(company_size IN ('1-10', '11-50', '51-200', '201-500', '501-1000', '1001-5000', '5000+')) OR company_size IS NULL", name: "chk_accounts_company_size_enum"
    add_check_constraint :accounts, "length(currency) <= 5", name: "chk_accounts_currency_length"
    add_check_constraint :accounts, "(length(parent_account_id) = 36) OR parent_account_id IS NULL", name: "chk_accounts_parent_account_id_uuid"
    add_index :accounts, [:parent_account_id], name: "idx_accounts_parent_account_id"
    add_check_constraint :accounts, "length(owner_id) = 36", name: "chk_accounts_owner_id_uuid"
    add_index :accounts, [:owner_id], name: "idx_accounts_owner_id"
    add_check_constraint :accounts, "status IN ('Active', 'Inactive')", name: "chk_accounts_status_enum"

    add_check_constraint :contacts, "length(id) = 36", name: "chk_contacts_id_uuid"
    add_check_constraint :contacts, "length(created_by) = 36", name: "chk_contacts_created_by_uuid"
    add_index :contacts, [:created_by], name: "idx_contacts_created_by"
    add_check_constraint :contacts, "length(updated_by) = 36", name: "chk_contacts_updated_by_uuid"
    add_index :contacts, [:updated_by], name: "idx_contacts_updated_by"
    add_check_constraint :contacts, "length(contact_number) <= 10", name: "chk_contacts_contact_number_length"
    add_index :contacts, [:contact_number], name: "idx_contacts_contact_number", unique: true
    add_check_constraint :contacts, "length(title) <= 30", name: "chk_contacts_title_length"
    add_check_constraint :contacts, "length(first_name) <= 40", name: "chk_contacts_first_name_length"
    add_check_constraint :contacts, "length(last_name) <= 40", name: "chk_contacts_last_name_length"
    add_check_constraint :contacts, "length(department) <= 40", name: "chk_contacts_department_length"
    add_check_constraint :contacts, "length(position) <= 40", name: "chk_contacts_position_length"
    add_check_constraint :contacts, "length(phone) <= 30", name: "chk_contacts_phone_length"
    add_check_constraint :contacts, "length(mobile) <= 30", name: "chk_contacts_mobile_length"
    add_check_constraint :contacts, "length(email) <= 241", name: "chk_contacts_email_length"
    add_check_constraint :contacts, "length(street) <= 60", name: "chk_contacts_street_length"
    add_check_constraint :contacts, "length(house_number) <= 10", name: "chk_contacts_house_number_length"
    add_check_constraint :contacts, "length(postal_code) <= 10", name: "chk_contacts_postal_code_length"
    add_check_constraint :contacts, "length(city) <= 40", name: "chk_contacts_city_length"
    add_check_constraint :contacts, "length(country) <= 3", name: "chk_contacts_country_length"
    add_check_constraint :contacts, "(length(account_id) = 36) OR account_id IS NULL", name: "chk_contacts_account_id_uuid"
    add_index :contacts, [:account_id], name: "idx_contacts_account_id"
    add_check_constraint :contacts, "length(owner_id) = 36", name: "chk_contacts_owner_id_uuid"
    add_index :contacts, [:owner_id], name: "idx_contacts_owner_id"
    add_check_constraint :contacts, "status IN ('Active', 'Inactive')", name: "chk_contacts_status_enum"

    add_check_constraint :contact_accounts, "length(id) = 36", name: "chk_contact_accounts_id_uuid"
    add_check_constraint :contact_accounts, "length(created_by) = 36", name: "chk_contact_accounts_created_by_uuid"
    add_index :contact_accounts, [:created_by], name: "idx_contact_accounts_created_by"
    add_check_constraint :contact_accounts, "length(updated_by) = 36", name: "chk_contact_accounts_updated_by_uuid"
    add_index :contact_accounts, [:updated_by], name: "idx_contact_accounts_updated_by"
    add_check_constraint :contact_accounts, "length(contact_id) = 36", name: "chk_contact_accounts_contact_id_uuid"
    add_index :contact_accounts, [:contact_id], name: "idx_contact_accounts_contact_id"
    add_check_constraint :contact_accounts, "length(account_id) = 36", name: "chk_contact_accounts_account_id_uuid"
    add_index :contact_accounts, [:account_id], name: "idx_contact_accounts_account_id"
    add_check_constraint :contact_accounts, "length(role) <= 50", name: "chk_contact_accounts_role_length"
    add_index :contact_accounts, [:contact_id, :account_id], name: "idx_contact_accounts_contact_id_account_id", unique: true

    add_check_constraint :leads, "length(id) = 36", name: "chk_leads_id_uuid"
    add_check_constraint :leads, "length(created_by) = 36", name: "chk_leads_created_by_uuid"
    add_index :leads, [:created_by], name: "idx_leads_created_by"
    add_check_constraint :leads, "length(updated_by) = 36", name: "chk_leads_updated_by_uuid"
    add_index :leads, [:updated_by], name: "idx_leads_updated_by"
    add_check_constraint :leads, "length(lead_number) <= 10", name: "chk_leads_lead_number_length"
    add_index :leads, [:lead_number], name: "idx_leads_lead_number", unique: true
    add_check_constraint :leads, "length(first_name) <= 40", name: "chk_leads_first_name_length"
    add_check_constraint :leads, "length(last_name) <= 40", name: "chk_leads_last_name_length"
    add_check_constraint :leads, "length(company) <= 40", name: "chk_leads_company_length"
    add_check_constraint :leads, "length(position) <= 40", name: "chk_leads_position_length"
    add_check_constraint :leads, "length(email) <= 241", name: "chk_leads_email_length"
    add_check_constraint :leads, "length(phone) <= 30", name: "chk_leads_phone_length"
    add_check_constraint :leads, "length(mobile) <= 30", name: "chk_leads_mobile_length"
    add_check_constraint :leads, "length(website) <= 132", name: "chk_leads_website_length"
    add_check_constraint :leads, "(source IN ('Web', 'Referral', 'Trade Show', 'Cold Call', 'Email Campaign', 'Social Media', 'Partner', 'Other')) OR source IS NULL", name: "chk_leads_source_enum"
    add_check_constraint :leads, "status IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Converted')", name: "chk_leads_status_enum"
    add_check_constraint :leads, "(length(account_id) = 36) OR account_id IS NULL", name: "chk_leads_account_id_uuid"
    add_index :leads, [:account_id], name: "idx_leads_account_id"
    add_check_constraint :leads, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_leads_contact_id_uuid"
    add_index :leads, [:contact_id], name: "idx_leads_contact_id"
    add_check_constraint :leads, "(length(converted_account_id) = 36) OR converted_account_id IS NULL", name: "chk_leads_converted_account_id_uuid"
    add_index :leads, [:converted_account_id], name: "idx_leads_converted_account_id"
    add_check_constraint :leads, "(length(converted_contact_id) = 36) OR converted_contact_id IS NULL", name: "chk_leads_converted_contact_id_uuid"
    add_index :leads, [:converted_contact_id], name: "idx_leads_converted_contact_id"
    add_check_constraint :leads, "(length(converted_opportunity_id) = 36) OR converted_opportunity_id IS NULL", name: "chk_leads_converted_opportunity_id_uuid"
    add_index :leads, [:converted_opportunity_id], name: "idx_leads_converted_opportunity_id"
    add_check_constraint :leads, "length(owner_id) = 36", name: "chk_leads_owner_id_uuid"
    add_index :leads, [:owner_id], name: "idx_leads_owner_id"

    add_check_constraint :opportunities, "length(id) = 36", name: "chk_opportunities_id_uuid"
    add_check_constraint :opportunities, "length(created_by) = 36", name: "chk_opportunities_created_by_uuid"
    add_index :opportunities, [:created_by], name: "idx_opportunities_created_by"
    add_check_constraint :opportunities, "length(updated_by) = 36", name: "chk_opportunities_updated_by_uuid"
    add_index :opportunities, [:updated_by], name: "idx_opportunities_updated_by"
    add_check_constraint :opportunities, "length(opportunity_number) <= 10", name: "chk_opportunities_opportunity_number_length"
    add_index :opportunities, [:opportunity_number], name: "idx_opportunities_opportunity_number", unique: true
    add_check_constraint :opportunities, "length(name) <= 120", name: "chk_opportunities_name_length"
    add_check_constraint :opportunities, "length(account_id) = 36", name: "chk_opportunities_account_id_uuid"
    add_index :opportunities, [:account_id], name: "idx_opportunities_account_id"
    add_check_constraint :opportunities, "(length(lead_id) = 36) OR lead_id IS NULL", name: "chk_opportunities_lead_id_uuid"
    add_index :opportunities, [:lead_id], name: "idx_opportunities_lead_id"
    add_check_constraint :opportunities, "length(stage_id) = 36", name: "chk_opportunities_stage_id_uuid"
    add_index :opportunities, [:stage_id], name: "idx_opportunities_stage_id"
    add_check_constraint :opportunities, "length(currency) <= 5", name: "chk_opportunities_currency_length"
    add_check_constraint :opportunities, "result IN ('Open', 'Won', 'Lost')", name: "chk_opportunities_result_enum"
    add_check_constraint :opportunities, "length(loss_reason) <= 255", name: "chk_opportunities_loss_reason_length"
    add_check_constraint :opportunities, "length(owner_id) = 36", name: "chk_opportunities_owner_id_uuid"
    add_index :opportunities, [:owner_id], name: "idx_opportunities_owner_id"

    add_check_constraint :opportunity_contacts, "length(id) = 36", name: "chk_opportunity_contacts_id_uuid"
    add_check_constraint :opportunity_contacts, "length(created_by) = 36", name: "chk_opportunity_contacts_created_by_uuid"
    add_index :opportunity_contacts, [:created_by], name: "idx_opportunity_contacts_created_by"
    add_check_constraint :opportunity_contacts, "length(updated_by) = 36", name: "chk_opportunity_contacts_updated_by_uuid"
    add_index :opportunity_contacts, [:updated_by], name: "idx_opportunity_contacts_updated_by"
    add_check_constraint :opportunity_contacts, "length(opportunity_id) = 36", name: "chk_opportunity_contacts_opportunity_id_uuid"
    add_index :opportunity_contacts, [:opportunity_id], name: "idx_opportunity_contacts_opportunity_id"
    add_check_constraint :opportunity_contacts, "length(contact_id) = 36", name: "chk_opportunity_contacts_contact_id_uuid"
    add_index :opportunity_contacts, [:contact_id], name: "idx_opportunity_contacts_contact_id"
    add_check_constraint :opportunity_contacts, "length(role) <= 50", name: "chk_opportunity_contacts_role_length"
    add_index :opportunity_contacts, [:opportunity_id, :contact_id], name: "idx_opportunity_contacts_opportunity_id_contact_id", unique: true

    add_check_constraint :deal_rooms, "length(id) = 36", name: "chk_deal_rooms_id_uuid"
    add_check_constraint :deal_rooms, "length(created_by) = 36", name: "chk_deal_rooms_created_by_uuid"
    add_index :deal_rooms, [:created_by], name: "idx_deal_rooms_created_by"
    add_check_constraint :deal_rooms, "length(updated_by) = 36", name: "chk_deal_rooms_updated_by_uuid"
    add_index :deal_rooms, [:updated_by], name: "idx_deal_rooms_updated_by"
    add_check_constraint :deal_rooms, "length(deal_room_number) <= 10", name: "chk_deal_rooms_deal_room_number_length"
    add_index :deal_rooms, [:deal_room_number], name: "idx_deal_rooms_deal_room_number", unique: true
    add_check_constraint :deal_rooms, "length(name) <= 120", name: "chk_deal_rooms_name_length"
    add_check_constraint :deal_rooms, "length(opportunity_id) = 36", name: "chk_deal_rooms_opportunity_id_uuid"
    add_index :deal_rooms, [:opportunity_id], name: "idx_deal_rooms_opportunity_id"
    add_check_constraint :deal_rooms, "status IN ('Active', 'Closed')", name: "chk_deal_rooms_status_enum"
    add_check_constraint :deal_rooms, "length(owner_id) = 36", name: "chk_deal_rooms_owner_id_uuid"
    add_index :deal_rooms, [:owner_id], name: "idx_deal_rooms_owner_id"

    add_check_constraint :pipeline_stages, "length(id) = 36", name: "chk_pipeline_stages_id_uuid"
    add_check_constraint :pipeline_stages, "length(created_by) = 36", name: "chk_pipeline_stages_created_by_uuid"
    add_index :pipeline_stages, [:created_by], name: "idx_pipeline_stages_created_by"
    add_check_constraint :pipeline_stages, "length(updated_by) = 36", name: "chk_pipeline_stages_updated_by_uuid"
    add_index :pipeline_stages, [:updated_by], name: "idx_pipeline_stages_updated_by"
    add_check_constraint :pipeline_stages, "length(name) <= 50", name: "chk_pipeline_stages_name_length"
    add_check_constraint :pipeline_stages, "length(description) <= 255", name: "chk_pipeline_stages_description_length"

    add_check_constraint :quotations, "length(id) = 36", name: "chk_quotations_id_uuid"
    add_check_constraint :quotations, "length(created_by) = 36", name: "chk_quotations_created_by_uuid"
    add_index :quotations, [:created_by], name: "idx_quotations_created_by"
    add_check_constraint :quotations, "length(updated_by) = 36", name: "chk_quotations_updated_by_uuid"
    add_index :quotations, [:updated_by], name: "idx_quotations_updated_by"
    add_check_constraint :quotations, "length(quotation_number) <= 10", name: "chk_quotations_quotation_number_length"
    add_index :quotations, [:quotation_number], name: "idx_quotations_quotation_number", unique: true
    add_check_constraint :quotations, "length(account_id) = 36", name: "chk_quotations_account_id_uuid"
    add_index :quotations, [:account_id], name: "idx_quotations_account_id"
    add_check_constraint :quotations, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_quotations_contact_id_uuid"
    add_index :quotations, [:contact_id], name: "idx_quotations_contact_id"
    add_check_constraint :quotations, "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_quotations_opportunity_id_uuid"
    add_index :quotations, [:opportunity_id], name: "idx_quotations_opportunity_id"
    add_check_constraint :quotations, "status IN ('Draft', 'Sent', 'Accepted', 'Rejected', 'Expired')", name: "chk_quotations_status_enum"
    add_check_constraint :quotations, "length(currency) <= 5", name: "chk_quotations_currency_length"
    add_check_constraint :quotations, "length(owner_id) = 36", name: "chk_quotations_owner_id_uuid"
    add_index :quotations, [:owner_id], name: "idx_quotations_owner_id"

    add_check_constraint :sales_orders, "length(id) = 36", name: "chk_sales_orders_id_uuid"
    add_check_constraint :sales_orders, "length(created_by) = 36", name: "chk_sales_orders_created_by_uuid"
    add_index :sales_orders, [:created_by], name: "idx_sales_orders_created_by"
    add_check_constraint :sales_orders, "length(updated_by) = 36", name: "chk_sales_orders_updated_by_uuid"
    add_index :sales_orders, [:updated_by], name: "idx_sales_orders_updated_by"
    add_check_constraint :sales_orders, "length(order_number) <= 10", name: "chk_sales_orders_order_number_length"
    add_index :sales_orders, [:order_number], name: "idx_sales_orders_order_number", unique: true
    add_check_constraint :sales_orders, "length(account_id) = 36", name: "chk_sales_orders_account_id_uuid"
    add_index :sales_orders, [:account_id], name: "idx_sales_orders_account_id"
    add_check_constraint :sales_orders, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_sales_orders_contact_id_uuid"
    add_index :sales_orders, [:contact_id], name: "idx_sales_orders_contact_id"
    add_check_constraint :sales_orders, "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_sales_orders_opportunity_id_uuid"
    add_index :sales_orders, [:opportunity_id], name: "idx_sales_orders_opportunity_id"
    add_check_constraint :sales_orders, "(length(quotation_id) = 36) OR quotation_id IS NULL", name: "chk_sales_orders_quotation_id_uuid"
    add_index :sales_orders, [:quotation_id], name: "idx_sales_orders_quotation_id"
    add_check_constraint :sales_orders, "status IN ('Draft', 'Confirmed', 'In Progress', 'Shipped', 'Completed', 'Cancelled')", name: "chk_sales_orders_status_enum"
    add_check_constraint :sales_orders, "length(currency) <= 5", name: "chk_sales_orders_currency_length"
    add_check_constraint :sales_orders, "length(owner_id) = 36", name: "chk_sales_orders_owner_id_uuid"
    add_index :sales_orders, [:owner_id], name: "idx_sales_orders_owner_id"

    add_check_constraint :invoices, "length(id) = 36", name: "chk_invoices_id_uuid"
    add_check_constraint :invoices, "length(created_by) = 36", name: "chk_invoices_created_by_uuid"
    add_index :invoices, [:created_by], name: "idx_invoices_created_by"
    add_check_constraint :invoices, "length(updated_by) = 36", name: "chk_invoices_updated_by_uuid"
    add_index :invoices, [:updated_by], name: "idx_invoices_updated_by"
    add_check_constraint :invoices, "length(invoice_number) <= 10", name: "chk_invoices_invoice_number_length"
    add_index :invoices, [:invoice_number], name: "idx_invoices_invoice_number", unique: true
    add_check_constraint :invoices, "length(account_id) = 36", name: "chk_invoices_account_id_uuid"
    add_index :invoices, [:account_id], name: "idx_invoices_account_id"
    add_check_constraint :invoices, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_invoices_contact_id_uuid"
    add_index :invoices, [:contact_id], name: "idx_invoices_contact_id"
    add_check_constraint :invoices, "(length(sales_order_id) = 36) OR sales_order_id IS NULL", name: "chk_invoices_sales_order_id_uuid"
    add_index :invoices, [:sales_order_id], name: "idx_invoices_sales_order_id"
    add_check_constraint :invoices, "status IN ('Draft', 'Sent', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled')", name: "chk_invoices_status_enum"
    add_check_constraint :invoices, "length(currency) <= 5", name: "chk_invoices_currency_length"
    add_check_constraint :invoices, "length(owner_id) = 36", name: "chk_invoices_owner_id_uuid"
    add_index :invoices, [:owner_id], name: "idx_invoices_owner_id"

    add_check_constraint :line_items, "length(id) = 36", name: "chk_line_items_id_uuid"
    add_check_constraint :line_items, "length(created_by) = 36", name: "chk_line_items_created_by_uuid"
    add_index :line_items, [:created_by], name: "idx_line_items_created_by"
    add_check_constraint :line_items, "length(updated_by) = 36", name: "chk_line_items_updated_by_uuid"
    add_index :line_items, [:updated_by], name: "idx_line_items_updated_by"
    add_check_constraint :line_items, "parent_type IN ('Opportunity', 'Quotation', 'SalesOrder', 'Invoice')", name: "chk_line_items_parent_type_enum"
    add_check_constraint :line_items, "length(parent_id) = 36", name: "chk_line_items_parent_id_uuid"
    add_check_constraint :line_items, "length(item_number) <= 6", name: "chk_line_items_item_number_length"
    add_check_constraint :line_items, "length(product_id) = 36", name: "chk_line_items_product_id_uuid"
    add_index :line_items, [:product_id], name: "idx_line_items_product_id"
    add_check_constraint :line_items, "length(unit_of_measure) <= 3", name: "chk_line_items_unit_of_measure_length"
    add_check_constraint :line_items, "length(comment) <= 40", name: "chk_line_items_comment_length"
    add_check_constraint :line_items, "length(alternative_to) <= 6", name: "chk_line_items_alternative_to_length"
    add_index :line_items, [:parent_type, :parent_id, :item_number], name: "idx_line_items_parent_type_parent_id_item_number", unique: true
    add_index :line_items, [:parent_type, :parent_id], name: "idx_line_items_parent_type_parent_id"

    add_check_constraint :pricebook_entries, "length(id) = 36", name: "chk_pricebook_entries_id_uuid"
    add_check_constraint :pricebook_entries, "length(created_by) = 36", name: "chk_pricebook_entries_created_by_uuid"
    add_index :pricebook_entries, [:created_by], name: "idx_pricebook_entries_created_by"
    add_check_constraint :pricebook_entries, "length(updated_by) = 36", name: "chk_pricebook_entries_updated_by_uuid"
    add_index :pricebook_entries, [:updated_by], name: "idx_pricebook_entries_updated_by"
    add_check_constraint :pricebook_entries, "length(product_id) = 36", name: "chk_pricebook_entries_product_id_uuid"
    add_index :pricebook_entries, [:product_id], name: "idx_pricebook_entries_product_id"
    add_check_constraint :pricebook_entries, "(length(account_id) = 36) OR account_id IS NULL", name: "chk_pricebook_entries_account_id_uuid"
    add_index :pricebook_entries, [:account_id], name: "idx_pricebook_entries_account_id"
    add_check_constraint :pricebook_entries, "length(currency) <= 5", name: "chk_pricebook_entries_currency_length"

    add_check_constraint :products, "length(id) = 36", name: "chk_products_id_uuid"
    add_check_constraint :products, "length(created_by) = 36", name: "chk_products_created_by_uuid"
    add_index :products, [:created_by], name: "idx_products_created_by"
    add_check_constraint :products, "length(updated_by) = 36", name: "chk_products_updated_by_uuid"
    add_index :products, [:updated_by], name: "idx_products_updated_by"
    add_check_constraint :products, "length(product_number) <= 40", name: "chk_products_product_number_length"
    add_index :products, [:product_number], name: "idx_products_product_number", unique: true
    add_check_constraint :products, "length(name) <= 40", name: "chk_products_name_length"
    add_check_constraint :products, "length(product_group) <= 9", name: "chk_products_product_group_length"
    add_check_constraint :products, "length(product_group_description) <= 100", name: "chk_products_product_group_description_length"
    add_check_constraint :products, "length(unit_of_measure) <= 3", name: "chk_products_unit_of_measure_length"
    add_check_constraint :products, "length(currency) <= 5", name: "chk_products_currency_length"
    add_check_constraint :products, "product_type IN ('Physical', 'Service', 'Subscription', 'License')", name: "chk_products_product_type_enum"
    add_check_constraint :products, "status IN ('Active', 'Inactive', 'Discontinued')", name: "chk_products_status_enum"

    add_check_constraint :activities, "length(id) = 36", name: "chk_activities_id_uuid"
    add_check_constraint :activities, "length(created_by) = 36", name: "chk_activities_created_by_uuid"
    add_index :activities, [:created_by], name: "idx_activities_created_by"
    add_check_constraint :activities, "length(updated_by) = 36", name: "chk_activities_updated_by_uuid"
    add_index :activities, [:updated_by], name: "idx_activities_updated_by"
    add_check_constraint :activities, "length(activity_number) <= 10", name: "chk_activities_activity_number_length"
    add_index :activities, [:activity_number], name: "idx_activities_activity_number", unique: true
    add_check_constraint :activities, "type IN ('Call', 'Email', 'Meeting', 'Task')", name: "chk_activities_type_enum"
    add_check_constraint :activities, "length(subject) <= 255", name: "chk_activities_subject_length"
    add_check_constraint :activities, "status IN ('Planned', 'In Progress', 'Completed', 'Cancelled')", name: "chk_activities_status_enum"
    add_check_constraint :activities, "(priority IN ('Low', 'Medium', 'High')) OR priority IS NULL", name: "chk_activities_priority_enum"
    add_check_constraint :activities, "(length(account_id) = 36) OR account_id IS NULL", name: "chk_activities_account_id_uuid"
    add_index :activities, [:account_id], name: "idx_activities_account_id"
    add_check_constraint :activities, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_activities_contact_id_uuid"
    add_index :activities, [:contact_id], name: "idx_activities_contact_id"
    add_check_constraint :activities, "(length(lead_id) = 36) OR lead_id IS NULL", name: "chk_activities_lead_id_uuid"
    add_index :activities, [:lead_id], name: "idx_activities_lead_id"
    add_check_constraint :activities, "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_activities_opportunity_id_uuid"
    add_index :activities, [:opportunity_id], name: "idx_activities_opportunity_id"
    add_check_constraint :activities, "(length(ticket_id) = 36) OR ticket_id IS NULL", name: "chk_activities_ticket_id_uuid"
    add_index :activities, [:ticket_id], name: "idx_activities_ticket_id"
    add_check_constraint :activities, "length(owner_id) = 36", name: "chk_activities_owner_id_uuid"
    add_index :activities, [:owner_id], name: "idx_activities_owner_id"

    add_check_constraint :tickets, "length(id) = 36", name: "chk_tickets_id_uuid"
    add_check_constraint :tickets, "length(created_by) = 36", name: "chk_tickets_created_by_uuid"
    add_index :tickets, [:created_by], name: "idx_tickets_created_by"
    add_check_constraint :tickets, "length(updated_by) = 36", name: "chk_tickets_updated_by_uuid"
    add_index :tickets, [:updated_by], name: "idx_tickets_updated_by"
    add_check_constraint :tickets, "length(ticket_number) <= 12", name: "chk_tickets_ticket_number_length"
    add_index :tickets, [:ticket_number], name: "idx_tickets_ticket_number", unique: true
    add_check_constraint :tickets, "length(subject) <= 40", name: "chk_tickets_subject_length"
    add_check_constraint :tickets, "length(status_id) = 36", name: "chk_tickets_status_id_uuid"
    add_index :tickets, [:status_id], name: "idx_tickets_status_id"
    add_check_constraint :tickets, "priority IN ('Low', 'Medium', 'High', 'Critical')", name: "chk_tickets_priority_enum"
    add_check_constraint :tickets, "length(category) <= 50", name: "chk_tickets_category_length"
    add_check_constraint :tickets, "length(account_id) = 36", name: "chk_tickets_account_id_uuid"
    add_index :tickets, [:account_id], name: "idx_tickets_account_id"
    add_check_constraint :tickets, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_tickets_contact_id_uuid"
    add_index :tickets, [:contact_id], name: "idx_tickets_contact_id"
    add_check_constraint :tickets, "(length(asset_id) = 36) OR asset_id IS NULL", name: "chk_tickets_asset_id_uuid"
    add_index :tickets, [:asset_id], name: "idx_tickets_asset_id"
    add_check_constraint :tickets, "(length(service_contract_id) = 36) OR service_contract_id IS NULL", name: "chk_tickets_service_contract_id_uuid"
    add_index :tickets, [:service_contract_id], name: "idx_tickets_service_contract_id"
    add_check_constraint :tickets, "(length(sla_id) = 36) OR sla_id IS NULL", name: "chk_tickets_sla_id_uuid"
    add_index :tickets, [:sla_id], name: "idx_tickets_sla_id"
    add_check_constraint :tickets, "(length(assigned_to) = 36) OR assigned_to IS NULL", name: "chk_tickets_assigned_to_uuid"
    add_index :tickets, [:assigned_to], name: "idx_tickets_assigned_to"
    add_check_constraint :tickets, "length(owner_id) = 36", name: "chk_tickets_owner_id_uuid"
    add_index :tickets, [:owner_id], name: "idx_tickets_owner_id"

    add_check_constraint :ticket_statuses, "length(id) = 36", name: "chk_ticket_statuses_id_uuid"
    add_check_constraint :ticket_statuses, "length(created_by) = 36", name: "chk_ticket_statuses_created_by_uuid"
    add_index :ticket_statuses, [:created_by], name: "idx_ticket_statuses_created_by"
    add_check_constraint :ticket_statuses, "length(updated_by) = 36", name: "chk_ticket_statuses_updated_by_uuid"
    add_index :ticket_statuses, [:updated_by], name: "idx_ticket_statuses_updated_by"
    add_check_constraint :ticket_statuses, "length(name) <= 50", name: "chk_ticket_statuses_name_length"
    add_check_constraint :ticket_statuses, "length(description) <= 255", name: "chk_ticket_statuses_description_length"

    add_check_constraint :slas, "length(id) = 36", name: "chk_slas_id_uuid"
    add_check_constraint :slas, "length(created_by) = 36", name: "chk_slas_created_by_uuid"
    add_index :slas, [:created_by], name: "idx_slas_created_by"
    add_check_constraint :slas, "length(updated_by) = 36", name: "chk_slas_updated_by_uuid"
    add_index :slas, [:updated_by], name: "idx_slas_updated_by"
    add_check_constraint :slas, "length(name) <= 100", name: "chk_slas_name_length"
    add_check_constraint :slas, "(json_valid(applies_to_priorities)) OR applies_to_priorities IS NULL", name: "chk_slas_applies_to_priorities_json"

    add_check_constraint :knowledge_articles, "length(id) = 36", name: "chk_knowledge_articles_id_uuid"
    add_check_constraint :knowledge_articles, "length(created_by) = 36", name: "chk_knowledge_articles_created_by_uuid"
    add_index :knowledge_articles, [:created_by], name: "idx_knowledge_articles_created_by"
    add_check_constraint :knowledge_articles, "length(updated_by) = 36", name: "chk_knowledge_articles_updated_by_uuid"
    add_index :knowledge_articles, [:updated_by], name: "idx_knowledge_articles_updated_by"
    add_check_constraint :knowledge_articles, "length(article_number) <= 10", name: "chk_knowledge_articles_article_number_length"
    add_index :knowledge_articles, [:article_number], name: "idx_knowledge_articles_article_number", unique: true
    add_check_constraint :knowledge_articles, "length(title) <= 255", name: "chk_knowledge_articles_title_length"
    add_check_constraint :knowledge_articles, "length(category) <= 100", name: "chk_knowledge_articles_category_length"
    add_check_constraint :knowledge_articles, "status IN ('Draft', 'In Review', 'Published', 'Archived')", name: "chk_knowledge_articles_status_enum"
    add_check_constraint :knowledge_articles, "source IN ('Manual', 'AI Generated', 'Case Conversion')", name: "chk_knowledge_articles_source_enum"
    add_check_constraint :knowledge_articles, "length(author_id) = 36", name: "chk_knowledge_articles_author_id_uuid"
    add_index :knowledge_articles, [:author_id], name: "idx_knowledge_articles_author_id"

    add_check_constraint :ticket_knowledge_articles, "length(id) = 36", name: "chk_ticket_knowledge_articles_id_uuid"
    add_check_constraint :ticket_knowledge_articles, "length(created_by) = 36", name: "chk_ticket_knowledge_articles_created_by_uuid"
    add_index :ticket_knowledge_articles, [:created_by], name: "idx_ticket_knowledge_articles_created_by"
    add_check_constraint :ticket_knowledge_articles, "length(updated_by) = 36", name: "chk_ticket_knowledge_articles_updated_by_uuid"
    add_index :ticket_knowledge_articles, [:updated_by], name: "idx_ticket_knowledge_articles_updated_by"
    add_check_constraint :ticket_knowledge_articles, "length(ticket_id) = 36", name: "chk_ticket_knowledge_articles_ticket_id_uuid"
    add_index :ticket_knowledge_articles, [:ticket_id], name: "idx_ticket_knowledge_articles_ticket_id"
    add_check_constraint :ticket_knowledge_articles, "length(article_id) = 36", name: "chk_ticket_knowledge_articles_article_id_uuid"
    add_index :ticket_knowledge_articles, [:article_id], name: "idx_ticket_knowledge_articles_article_id"
    add_check_constraint :ticket_knowledge_articles, "length(linked_by) = 36", name: "chk_ticket_knowledge_articles_linked_by_uuid"
    add_index :ticket_knowledge_articles, [:linked_by], name: "idx_ticket_knowledge_articles_linked_by"
    add_index :ticket_knowledge_articles, [:ticket_id, :article_id], name: "idx_ticket_knowledge_articles_ticket_id_article_id", unique: true

    add_check_constraint :service_contracts, "length(id) = 36", name: "chk_service_contracts_id_uuid"
    add_check_constraint :service_contracts, "length(created_by) = 36", name: "chk_service_contracts_created_by_uuid"
    add_index :service_contracts, [:created_by], name: "idx_service_contracts_created_by"
    add_check_constraint :service_contracts, "length(updated_by) = 36", name: "chk_service_contracts_updated_by_uuid"
    add_index :service_contracts, [:updated_by], name: "idx_service_contracts_updated_by"
    add_check_constraint :service_contracts, "length(contract_number) <= 10", name: "chk_service_contracts_contract_number_length"
    add_index :service_contracts, [:contract_number], name: "idx_service_contracts_contract_number", unique: true
    add_check_constraint :service_contracts, "length(name) <= 120", name: "chk_service_contracts_name_length"
    add_check_constraint :service_contracts, "length(account_id) = 36", name: "chk_service_contracts_account_id_uuid"
    add_index :service_contracts, [:account_id], name: "idx_service_contracts_account_id"
    add_check_constraint :service_contracts, "status IN ('Draft', 'Active', 'Expired', 'Terminated')", name: "chk_service_contracts_status_enum"
    add_check_constraint :service_contracts, "(length(sla_id) = 36) OR sla_id IS NULL", name: "chk_service_contracts_sla_id_uuid"
    add_index :service_contracts, [:sla_id], name: "idx_service_contracts_sla_id"
    add_check_constraint :service_contracts, "length(owner_id) = 36", name: "chk_service_contracts_owner_id_uuid"
    add_index :service_contracts, [:owner_id], name: "idx_service_contracts_owner_id"

    add_check_constraint :assets, "length(id) = 36", name: "chk_assets_id_uuid"
    add_check_constraint :assets, "length(created_by) = 36", name: "chk_assets_created_by_uuid"
    add_index :assets, [:created_by], name: "idx_assets_created_by"
    add_check_constraint :assets, "length(updated_by) = 36", name: "chk_assets_updated_by_uuid"
    add_index :assets, [:updated_by], name: "idx_assets_updated_by"
    add_check_constraint :assets, "length(asset_number) <= 18", name: "chk_assets_asset_number_length"
    add_index :assets, [:asset_number], name: "idx_assets_asset_number", unique: true
    add_check_constraint :assets, "length(name) <= 40", name: "chk_assets_name_length"
    add_check_constraint :assets, "length(product_id) = 36", name: "chk_assets_product_id_uuid"
    add_index :assets, [:product_id], name: "idx_assets_product_id"
    add_check_constraint :assets, "length(account_id) = 36", name: "chk_assets_account_id_uuid"
    add_index :assets, [:account_id], name: "idx_assets_account_id"
    add_check_constraint :assets, "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_assets_contact_id_uuid"
    add_index :assets, [:contact_id], name: "idx_assets_contact_id"
    add_check_constraint :assets, "length(serial_number) <= 18", name: "chk_assets_serial_number_length"
    add_check_constraint :assets, "length(functional_location) <= 30", name: "chk_assets_functional_location_length"
    add_check_constraint :assets, "length(manufacturer) <= 30", name: "chk_assets_manufacturer_length"
    add_check_constraint :assets, "length(model_number) <= 20", name: "chk_assets_model_number_length"
    add_check_constraint :assets, "status IN ('Active', 'Inactive', 'Retired', 'In Repair')", name: "chk_assets_status_enum"
    add_check_constraint :assets, "length(owner_id) = 36", name: "chk_assets_owner_id_uuid"
    add_index :assets, [:owner_id], name: "idx_assets_owner_id"

    add_check_constraint :documents, "length(id) = 36", name: "chk_documents_id_uuid"
    add_check_constraint :documents, "length(created_by) = 36", name: "chk_documents_created_by_uuid"
    add_index :documents, [:created_by], name: "idx_documents_created_by"
    add_check_constraint :documents, "length(updated_by) = 36", name: "chk_documents_updated_by_uuid"
    add_index :documents, [:updated_by], name: "idx_documents_updated_by"
    add_check_constraint :documents, "length(name) <= 255", name: "chk_documents_name_length"
    add_check_constraint :documents, "length(file_path) <= 500", name: "chk_documents_file_path_length"
    add_check_constraint :documents, "length(file_type) <= 50", name: "chk_documents_file_type_length"
    add_check_constraint :documents, "parent_type IN ('Account', 'Contact', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle', 'DealRoom')", name: "chk_documents_parent_type_enum"
    add_check_constraint :documents, "length(parent_id) = 36", name: "chk_documents_parent_id_uuid"
    add_check_constraint :documents, "length(uploaded_by) = 36", name: "chk_documents_uploaded_by_uuid"
    add_index :documents, [:uploaded_by], name: "idx_documents_uploaded_by"
    add_index :documents, [:parent_type, :parent_id], name: "idx_documents_parent_type_parent_id"

    add_check_constraint :comments, "length(id) = 36", name: "chk_comments_id_uuid"
    add_check_constraint :comments, "length(created_by) = 36", name: "chk_comments_created_by_uuid"
    add_index :comments, [:created_by], name: "idx_comments_created_by"
    add_check_constraint :comments, "length(updated_by) = 36", name: "chk_comments_updated_by_uuid"
    add_index :comments, [:updated_by], name: "idx_comments_updated_by"
    add_check_constraint :comments, "parent_type IN ('Account', 'Contact', 'Lead', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle', 'Activity', 'DealRoom')", name: "chk_comments_parent_type_enum"
    add_check_constraint :comments, "length(parent_id) = 36", name: "chk_comments_parent_id_uuid"
    add_check_constraint :comments, "length(author_id) = 36", name: "chk_comments_author_id_uuid"
    add_index :comments, [:author_id], name: "idx_comments_author_id"
    add_index :comments, [:parent_type, :parent_id], name: "idx_comments_parent_type_parent_id"

    add_check_constraint :user_profiles, "length(id) = 36", name: "chk_user_profiles_id_uuid"
    add_check_constraint :user_profiles, "length(created_by) = 36", name: "chk_user_profiles_created_by_uuid"
    add_index :user_profiles, [:created_by], name: "idx_user_profiles_created_by"
    add_check_constraint :user_profiles, "length(updated_by) = 36", name: "chk_user_profiles_updated_by_uuid"
    add_index :user_profiles, [:updated_by], name: "idx_user_profiles_updated_by"
    add_check_constraint :user_profiles, "length(auth_uid) <= 128", name: "chk_user_profiles_auth_uid_length"
    add_index :user_profiles, [:auth_uid], name: "idx_user_profiles_auth_uid", unique: true
    add_check_constraint :user_profiles, "length(email) <= 241", name: "chk_user_profiles_email_length"
    add_index :user_profiles, [:email], name: "idx_user_profiles_email", unique: true
    add_check_constraint :user_profiles, "length(first_name) <= 40", name: "chk_user_profiles_first_name_length"
    add_check_constraint :user_profiles, "length(last_name) <= 40", name: "chk_user_profiles_last_name_length"
    add_check_constraint :user_profiles, "length(role_id) = 36", name: "chk_user_profiles_role_id_uuid"
    add_index :user_profiles, [:role_id], name: "idx_user_profiles_role_id"
    add_check_constraint :user_profiles, "(length(team_id) = 36) OR team_id IS NULL", name: "chk_user_profiles_team_id_uuid"
    add_index :user_profiles, [:team_id], name: "idx_user_profiles_team_id"
    add_check_constraint :user_profiles, "length(avatar_url) <= 2048", name: "chk_user_profiles_avatar_url_length"
    add_check_constraint :user_profiles, "length(level_name) <= 50", name: "chk_user_profiles_level_name_length"
    add_check_constraint :user_profiles, "theme_preference IN ('Light', 'Dark', 'System')", name: "chk_user_profiles_theme_preference_enum"
    add_check_constraint :user_profiles, "(json_valid(notification_preferences)) OR notification_preferences IS NULL", name: "chk_user_profiles_notification_preferences_json"
    add_check_constraint :user_profiles, "length(language_preference) <= 5", name: "chk_user_profiles_language_preference_length"

    add_check_constraint :roles, "length(id) = 36", name: "chk_roles_id_uuid"
    add_check_constraint :roles, "length(created_by) = 36", name: "chk_roles_created_by_uuid"
    add_index :roles, [:created_by], name: "idx_roles_created_by"
    add_check_constraint :roles, "length(updated_by) = 36", name: "chk_roles_updated_by_uuid"
    add_index :roles, [:updated_by], name: "idx_roles_updated_by"
    add_check_constraint :roles, "length(name) <= 50", name: "chk_roles_name_length"
    add_index :roles, [:name], name: "idx_roles_name", unique: true
    add_check_constraint :roles, "length(description) <= 255", name: "chk_roles_description_length"
    add_check_constraint :roles, "json_valid(permissions)", name: "chk_roles_permissions_json"
    add_check_constraint :roles, "json_valid(ribbon_items)", name: "chk_roles_ribbon_items_json"
    add_check_constraint :roles, "(json_valid(visible_cards)) OR visible_cards IS NULL", name: "chk_roles_visible_cards_json"
    add_check_constraint :roles, "(json_valid(layout_config)) OR layout_config IS NULL", name: "chk_roles_layout_config_json"

    add_check_constraint :teams, "length(id) = 36", name: "chk_teams_id_uuid"
    add_check_constraint :teams, "length(created_by) = 36", name: "chk_teams_created_by_uuid"
    add_index :teams, [:created_by], name: "idx_teams_created_by"
    add_check_constraint :teams, "length(updated_by) = 36", name: "chk_teams_updated_by_uuid"
    add_index :teams, [:updated_by], name: "idx_teams_updated_by"
    add_check_constraint :teams, "length(name) <= 100", name: "chk_teams_name_length"
    add_check_constraint :teams, "length(manager_id) = 36", name: "chk_teams_manager_id_uuid"
    add_index :teams, [:manager_id], name: "idx_teams_manager_id"
    add_check_constraint :teams, "length(description) <= 255", name: "chk_teams_description_length"

    add_check_constraint :notifications, "length(id) = 36", name: "chk_notifications_id_uuid"
    add_check_constraint :notifications, "length(created_by) = 36", name: "chk_notifications_created_by_uuid"
    add_index :notifications, [:created_by], name: "idx_notifications_created_by"
    add_check_constraint :notifications, "length(updated_by) = 36", name: "chk_notifications_updated_by_uuid"
    add_index :notifications, [:updated_by], name: "idx_notifications_updated_by"
    add_check_constraint :notifications, "length(user_id) = 36", name: "chk_notifications_user_id_uuid"
    add_index :notifications, [:user_id], name: "idx_notifications_user_id"
    add_check_constraint :notifications, "type IN ('TicketAssigned', 'SLABreach', 'DealStageChange', 'MentionedInComment', 'LeadAssigned', 'ChallengeAssigned', 'BadgeEarned', 'LevelUp', 'PersonalBest', 'System')", name: "chk_notifications_type_enum"
    add_check_constraint :notifications, "length(title) <= 255", name: "chk_notifications_title_length"
    add_check_constraint :notifications, "length(message) <= 500", name: "chk_notifications_message_length"
    add_check_constraint :notifications, "length(link_type) <= 50", name: "chk_notifications_link_type_length"
    add_check_constraint :notifications, "(length(link_id) = 36) OR link_id IS NULL", name: "chk_notifications_link_id_uuid"

    add_check_constraint :dashboard_configs, "length(id) = 36", name: "chk_dashboard_configs_id_uuid"
    add_check_constraint :dashboard_configs, "length(created_by) = 36", name: "chk_dashboard_configs_created_by_uuid"
    add_index :dashboard_configs, [:created_by], name: "idx_dashboard_configs_created_by"
    add_check_constraint :dashboard_configs, "length(updated_by) = 36", name: "chk_dashboard_configs_updated_by_uuid"
    add_index :dashboard_configs, [:updated_by], name: "idx_dashboard_configs_updated_by"
    add_check_constraint :dashboard_configs, "length(user_id) = 36", name: "chk_dashboard_configs_user_id_uuid"
    add_index :dashboard_configs, [:user_id], name: "idx_dashboard_configs_user_id"
    add_check_constraint :dashboard_configs, "length(name) <= 100", name: "chk_dashboard_configs_name_length"
    add_check_constraint :dashboard_configs, "json_valid(widgets)", name: "chk_dashboard_configs_widgets_json"
    add_index :dashboard_configs, [:user_id, :name], name: "idx_dashboard_configs_user_id_name", unique: true

    add_check_constraint :badges, "length(id) = 36", name: "chk_badges_id_uuid"
    add_check_constraint :badges, "length(created_by) = 36", name: "chk_badges_created_by_uuid"
    add_index :badges, [:created_by], name: "idx_badges_created_by"
    add_check_constraint :badges, "length(updated_by) = 36", name: "chk_badges_updated_by_uuid"
    add_index :badges, [:updated_by], name: "idx_badges_updated_by"
    add_check_constraint :badges, "length(name) <= 100", name: "chk_badges_name_length"
    add_index :badges, [:name], name: "idx_badges_name", unique: true
    add_check_constraint :badges, "length(description) <= 255", name: "chk_badges_description_length"
    add_check_constraint :badges, "length(icon_url) <= 500", name: "chk_badges_icon_url_length"
    add_check_constraint :badges, "category IN ('Sales', 'Service', 'Data Quality', 'Collaboration', 'Milestone', 'Challenge', 'Special')", name: "chk_badges_category_enum"
    add_check_constraint :badges, "json_valid(criteria)", name: "chk_badges_criteria_json"

    add_check_constraint :user_badges, "length(id) = 36", name: "chk_user_badges_id_uuid"
    add_check_constraint :user_badges, "length(created_by) = 36", name: "chk_user_badges_created_by_uuid"
    add_index :user_badges, [:created_by], name: "idx_user_badges_created_by"
    add_check_constraint :user_badges, "length(updated_by) = 36", name: "chk_user_badges_updated_by_uuid"
    add_index :user_badges, [:updated_by], name: "idx_user_badges_updated_by"
    add_check_constraint :user_badges, "length(user_id) = 36", name: "chk_user_badges_user_id_uuid"
    add_index :user_badges, [:user_id], name: "idx_user_badges_user_id"
    add_check_constraint :user_badges, "length(badge_id) = 36", name: "chk_user_badges_badge_id_uuid"
    add_index :user_badges, [:badge_id], name: "idx_user_badges_badge_id"
    add_index :user_badges, [:user_id, :badge_id], name: "idx_user_badges_user_id_badge_id", unique: true

    add_check_constraint :challenges, "length(id) = 36", name: "chk_challenges_id_uuid"
    add_check_constraint :challenges, "length(created_by) = 36", name: "chk_challenges_created_by_uuid"
    add_index :challenges, [:created_by], name: "idx_challenges_created_by"
    add_check_constraint :challenges, "length(updated_by) = 36", name: "chk_challenges_updated_by_uuid"
    add_index :challenges, [:updated_by], name: "idx_challenges_updated_by"
    add_check_constraint :challenges, "length(user_id) = 36", name: "chk_challenges_user_id_uuid"
    add_index :challenges, [:user_id], name: "idx_challenges_user_id"
    add_check_constraint :challenges, "length(title) <= 255", name: "chk_challenges_title_length"
    add_check_constraint :challenges, "length(target_metric) <= 100", name: "chk_challenges_target_metric_length"
    add_check_constraint :challenges, "status IN ('Active', 'Completed', 'Failed', 'Cancelled')", name: "chk_challenges_status_enum"
    add_check_constraint :challenges, "(length(reward_badge_id) = 36) OR reward_badge_id IS NULL", name: "chk_challenges_reward_badge_id_uuid"
    add_index :challenges, [:reward_badge_id], name: "idx_challenges_reward_badge_id"
    add_index :challenges, [:user_id, :month, :year], name: "idx_challenges_user_id_month_year", unique: true

    add_check_constraint :streaks, "length(id) = 36", name: "chk_streaks_id_uuid"
    add_check_constraint :streaks, "length(created_by) = 36", name: "chk_streaks_created_by_uuid"
    add_index :streaks, [:created_by], name: "idx_streaks_created_by"
    add_check_constraint :streaks, "length(updated_by) = 36", name: "chk_streaks_updated_by_uuid"
    add_index :streaks, [:updated_by], name: "idx_streaks_updated_by"
    add_check_constraint :streaks, "length(user_id) = 36", name: "chk_streaks_user_id_uuid"
    add_index :streaks, [:user_id], name: "idx_streaks_user_id"
    add_check_constraint :streaks, "length(activity_type) <= 50", name: "chk_streaks_activity_type_length"
    add_index :streaks, [:user_id, :activity_type], name: "idx_streaks_user_id_activity_type", unique: true

    add_check_constraint :personal_bests, "length(id) = 36", name: "chk_personal_bests_id_uuid"
    add_check_constraint :personal_bests, "length(created_by) = 36", name: "chk_personal_bests_created_by_uuid"
    add_index :personal_bests, [:created_by], name: "idx_personal_bests_created_by"
    add_check_constraint :personal_bests, "length(updated_by) = 36", name: "chk_personal_bests_updated_by_uuid"
    add_index :personal_bests, [:updated_by], name: "idx_personal_bests_updated_by"
    add_check_constraint :personal_bests, "length(user_id) = 36", name: "chk_personal_bests_user_id_uuid"
    add_index :personal_bests, [:user_id], name: "idx_personal_bests_user_id"
    add_check_constraint :personal_bests, "length(metric) <= 100", name: "chk_personal_bests_metric_length"
    add_index :personal_bests, [:user_id, :metric], name: "idx_personal_bests_user_id_metric", unique: true

    add_check_constraint :audit_logs, "length(id) = 36", name: "chk_audit_logs_id_uuid"
    add_check_constraint :audit_logs, "length(created_by) = 36", name: "chk_audit_logs_created_by_uuid"
    add_index :audit_logs, [:created_by], name: "idx_audit_logs_created_by"
    add_check_constraint :audit_logs, "length(updated_by) = 36", name: "chk_audit_logs_updated_by_uuid"
    add_index :audit_logs, [:updated_by], name: "idx_audit_logs_updated_by"
    add_check_constraint :audit_logs, "length(object_type) <= 50", name: "chk_audit_logs_object_type_length"
    add_check_constraint :audit_logs, "length(object_id) = 36", name: "chk_audit_logs_object_id_uuid"
    add_check_constraint :audit_logs, "action IN ('Create', 'Update', 'Delete')", name: "chk_audit_logs_action_enum"
    add_check_constraint :audit_logs, "length(field_name) <= 100", name: "chk_audit_logs_field_name_length"
    add_check_constraint :audit_logs, "length(user_id) = 36", name: "chk_audit_logs_user_id_uuid"
    add_index :audit_logs, [:user_id], name: "idx_audit_logs_user_id"
    add_check_constraint :audit_logs, "length(object_name) <= 255", name: "chk_audit_logs_object_name_length"
    add_check_constraint :audit_logs, "length(summary) <= 500", name: "chk_audit_logs_summary_length"
    add_index :audit_logs, [:object_type, :object_id], name: "idx_audit_logs_object_type_object_id"

    add_check_constraint :data_source_configs, "length(id) = 36", name: "chk_data_source_configs_id_uuid"
    add_check_constraint :data_source_configs, "length(created_by) = 36", name: "chk_data_source_configs_created_by_uuid"
    add_index :data_source_configs, [:created_by], name: "idx_data_source_configs_created_by"
    add_check_constraint :data_source_configs, "length(updated_by) = 36", name: "chk_data_source_configs_updated_by_uuid"
    add_index :data_source_configs, [:updated_by], name: "idx_data_source_configs_updated_by"
    add_check_constraint :data_source_configs, "length(object_type) <= 50", name: "chk_data_source_configs_object_type_length"
    add_index :data_source_configs, [:object_type], name: "idx_data_source_configs_object_type", unique: true
    add_check_constraint :data_source_configs, "source_type IN ('Local', 'External')", name: "chk_data_source_configs_source_type_enum"
    add_check_constraint :data_source_configs, "length(endpoint_url) <= 500", name: "chk_data_source_configs_endpoint_url_length"
    add_check_constraint :data_source_configs, "(auth_type IN ('None', 'BasicAuth', 'OAuth2', 'APIKey')) OR auth_type IS NULL", name: "chk_data_source_configs_auth_type_enum"
    add_check_constraint :data_source_configs, "(json_valid(auth_config)) OR auth_config IS NULL", name: "chk_data_source_configs_auth_config_json"
    add_check_constraint :data_source_configs, "(json_valid(field_mapping)) OR field_mapping IS NULL", name: "chk_data_source_configs_field_mapping_json"

    add_check_constraint :ai_provider_configs, "length(id) = 36", name: "chk_ai_provider_configs_id_uuid"
    add_check_constraint :ai_provider_configs, "length(created_by) = 36", name: "chk_ai_provider_configs_created_by_uuid"
    add_index :ai_provider_configs, [:created_by], name: "idx_ai_provider_configs_created_by"
    add_check_constraint :ai_provider_configs, "length(updated_by) = 36", name: "chk_ai_provider_configs_updated_by_uuid"
    add_index :ai_provider_configs, [:updated_by], name: "idx_ai_provider_configs_updated_by"
    add_check_constraint :ai_provider_configs, "provider IN ('OpenAI', 'Google', 'Anthropic', 'Moonshot')", name: "chk_ai_provider_configs_provider_enum"
    add_check_constraint :ai_provider_configs, "length(model) <= 100", name: "chk_ai_provider_configs_model_length"
    add_check_constraint :ai_provider_configs, "length(api_key) <= 500", name: "chk_ai_provider_configs_api_key_length"
    add_check_constraint :ai_provider_configs, "length(endpoint_url) <= 500", name: "chk_ai_provider_configs_endpoint_url_length"

    add_check_constraint :level_definitions, "length(id) = 36", name: "chk_level_definitions_id_uuid"
    add_check_constraint :level_definitions, "length(created_by) = 36", name: "chk_level_definitions_created_by_uuid"
    add_index :level_definitions, [:created_by], name: "idx_level_definitions_created_by"
    add_check_constraint :level_definitions, "length(updated_by) = 36", name: "chk_level_definitions_updated_by_uuid"
    add_index :level_definitions, [:updated_by], name: "idx_level_definitions_updated_by"
    add_index :level_definitions, [:level], name: "idx_level_definitions_level", unique: true
    add_check_constraint :level_definitions, "length(name) <= 50", name: "chk_level_definitions_name_length"
    add_check_constraint :level_definitions, "(json_valid(unlocks)) OR unlocks IS NULL", name: "chk_level_definitions_unlocks_json"
    add_check_constraint :level_definitions, "length(icon_url) <= 500", name: "chk_level_definitions_icon_url_length"

    add_check_constraint :xp_events, "length(id) = 36", name: "chk_xp_events_id_uuid"
    add_check_constraint :xp_events, "length(created_by) = 36", name: "chk_xp_events_created_by_uuid"
    add_index :xp_events, [:created_by], name: "idx_xp_events_created_by"
    add_check_constraint :xp_events, "length(updated_by) = 36", name: "chk_xp_events_updated_by_uuid"
    add_index :xp_events, [:updated_by], name: "idx_xp_events_updated_by"
    add_check_constraint :xp_events, "length(event_type) <= 100", name: "chk_xp_events_event_type_length"
    add_index :xp_events, [:event_type], name: "idx_xp_events_event_type", unique: true
    add_check_constraint :xp_events, "length(description) <= 255", name: "chk_xp_events_description_length"

    add_foreign_key :accounts, :user_profiles, column: :created_by, primary_key: :id, name: "fk_accounts_created_by", deferrable: :deferred
    add_foreign_key :accounts, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_accounts_updated_by", deferrable: :deferred
    add_foreign_key :accounts, :accounts, column: :parent_account_id, primary_key: :id, name: "fk_accounts_parent_account_id", deferrable: :deferred
    add_foreign_key :accounts, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_accounts_owner_id", deferrable: :deferred

    add_foreign_key :contacts, :user_profiles, column: :created_by, primary_key: :id, name: "fk_contacts_created_by", deferrable: :deferred
    add_foreign_key :contacts, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_contacts_updated_by", deferrable: :deferred
    add_foreign_key :contacts, :accounts, column: :account_id, primary_key: :id, name: "fk_contacts_account_id", deferrable: :deferred
    add_foreign_key :contacts, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_contacts_owner_id", deferrable: :deferred

    add_foreign_key :contact_accounts, :user_profiles, column: :created_by, primary_key: :id, name: "fk_contact_accounts_created_by", deferrable: :deferred
    add_foreign_key :contact_accounts, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_contact_accounts_updated_by", deferrable: :deferred
    add_foreign_key :contact_accounts, :contacts, column: :contact_id, primary_key: :id, name: "fk_contact_accounts_contact_id", deferrable: :deferred, on_delete: :cascade
    add_foreign_key :contact_accounts, :accounts, column: :account_id, primary_key: :id, name: "fk_contact_accounts_account_id", deferrable: :deferred, on_delete: :cascade

    add_foreign_key :leads, :user_profiles, column: :created_by, primary_key: :id, name: "fk_leads_created_by", deferrable: :deferred
    add_foreign_key :leads, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_leads_updated_by", deferrable: :deferred
    add_foreign_key :leads, :accounts, column: :account_id, primary_key: :id, name: "fk_leads_account_id", deferrable: :deferred
    add_foreign_key :leads, :contacts, column: :contact_id, primary_key: :id, name: "fk_leads_contact_id", deferrable: :deferred
    add_foreign_key :leads, :accounts, column: :converted_account_id, primary_key: :id, name: "fk_leads_converted_account_id", deferrable: :deferred
    add_foreign_key :leads, :contacts, column: :converted_contact_id, primary_key: :id, name: "fk_leads_converted_contact_id", deferrable: :deferred
    add_foreign_key :leads, :opportunities, column: :converted_opportunity_id, primary_key: :id, name: "fk_leads_converted_opportunity_id", deferrable: :deferred
    add_foreign_key :leads, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_leads_owner_id", deferrable: :deferred

    add_foreign_key :opportunities, :user_profiles, column: :created_by, primary_key: :id, name: "fk_opportunities_created_by", deferrable: :deferred
    add_foreign_key :opportunities, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_opportunities_updated_by", deferrable: :deferred
    add_foreign_key :opportunities, :accounts, column: :account_id, primary_key: :id, name: "fk_opportunities_account_id", deferrable: :deferred
    add_foreign_key :opportunities, :leads, column: :lead_id, primary_key: :id, name: "fk_opportunities_lead_id", deferrable: :deferred
    add_foreign_key :opportunities, :pipeline_stages, column: :stage_id, primary_key: :id, name: "fk_opportunities_stage_id", deferrable: :deferred
    add_foreign_key :opportunities, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_opportunities_owner_id", deferrable: :deferred

    add_foreign_key :opportunity_contacts, :user_profiles, column: :created_by, primary_key: :id, name: "fk_opportunity_contacts_created_by", deferrable: :deferred
    add_foreign_key :opportunity_contacts, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_opportunity_contacts_updated_by", deferrable: :deferred
    add_foreign_key :opportunity_contacts, :opportunities, column: :opportunity_id, primary_key: :id, name: "fk_opportunity_contacts_opportunity_id", deferrable: :deferred, on_delete: :cascade
    add_foreign_key :opportunity_contacts, :contacts, column: :contact_id, primary_key: :id, name: "fk_opportunity_contacts_contact_id", deferrable: :deferred, on_delete: :cascade

    add_foreign_key :deal_rooms, :user_profiles, column: :created_by, primary_key: :id, name: "fk_deal_rooms_created_by", deferrable: :deferred
    add_foreign_key :deal_rooms, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_deal_rooms_updated_by", deferrable: :deferred
    add_foreign_key :deal_rooms, :opportunities, column: :opportunity_id, primary_key: :id, name: "fk_deal_rooms_opportunity_id", deferrable: :deferred
    add_foreign_key :deal_rooms, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_deal_rooms_owner_id", deferrable: :deferred

    add_foreign_key :pipeline_stages, :user_profiles, column: :created_by, primary_key: :id, name: "fk_pipeline_stages_created_by", deferrable: :deferred
    add_foreign_key :pipeline_stages, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_pipeline_stages_updated_by", deferrable: :deferred

    add_foreign_key :quotations, :user_profiles, column: :created_by, primary_key: :id, name: "fk_quotations_created_by", deferrable: :deferred
    add_foreign_key :quotations, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_quotations_updated_by", deferrable: :deferred
    add_foreign_key :quotations, :accounts, column: :account_id, primary_key: :id, name: "fk_quotations_account_id", deferrable: :deferred
    add_foreign_key :quotations, :contacts, column: :contact_id, primary_key: :id, name: "fk_quotations_contact_id", deferrable: :deferred
    add_foreign_key :quotations, :opportunities, column: :opportunity_id, primary_key: :id, name: "fk_quotations_opportunity_id", deferrable: :deferred
    add_foreign_key :quotations, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_quotations_owner_id", deferrable: :deferred

    add_foreign_key :sales_orders, :user_profiles, column: :created_by, primary_key: :id, name: "fk_sales_orders_created_by", deferrable: :deferred
    add_foreign_key :sales_orders, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_sales_orders_updated_by", deferrable: :deferred
    add_foreign_key :sales_orders, :accounts, column: :account_id, primary_key: :id, name: "fk_sales_orders_account_id", deferrable: :deferred
    add_foreign_key :sales_orders, :contacts, column: :contact_id, primary_key: :id, name: "fk_sales_orders_contact_id", deferrable: :deferred
    add_foreign_key :sales_orders, :opportunities, column: :opportunity_id, primary_key: :id, name: "fk_sales_orders_opportunity_id", deferrable: :deferred
    add_foreign_key :sales_orders, :quotations, column: :quotation_id, primary_key: :id, name: "fk_sales_orders_quotation_id", deferrable: :deferred
    add_foreign_key :sales_orders, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_sales_orders_owner_id", deferrable: :deferred

    add_foreign_key :invoices, :user_profiles, column: :created_by, primary_key: :id, name: "fk_invoices_created_by", deferrable: :deferred
    add_foreign_key :invoices, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_invoices_updated_by", deferrable: :deferred
    add_foreign_key :invoices, :accounts, column: :account_id, primary_key: :id, name: "fk_invoices_account_id", deferrable: :deferred
    add_foreign_key :invoices, :contacts, column: :contact_id, primary_key: :id, name: "fk_invoices_contact_id", deferrable: :deferred
    add_foreign_key :invoices, :sales_orders, column: :sales_order_id, primary_key: :id, name: "fk_invoices_sales_order_id", deferrable: :deferred
    add_foreign_key :invoices, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_invoices_owner_id", deferrable: :deferred

    add_foreign_key :line_items, :user_profiles, column: :created_by, primary_key: :id, name: "fk_line_items_created_by", deferrable: :deferred
    add_foreign_key :line_items, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_line_items_updated_by", deferrable: :deferred
    add_foreign_key :line_items, :products, column: :product_id, primary_key: :id, name: "fk_line_items_product_id", deferrable: :deferred

    add_foreign_key :pricebook_entries, :user_profiles, column: :created_by, primary_key: :id, name: "fk_pricebook_entries_created_by", deferrable: :deferred
    add_foreign_key :pricebook_entries, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_pricebook_entries_updated_by", deferrable: :deferred
    add_foreign_key :pricebook_entries, :products, column: :product_id, primary_key: :id, name: "fk_pricebook_entries_product_id", deferrable: :deferred
    add_foreign_key :pricebook_entries, :accounts, column: :account_id, primary_key: :id, name: "fk_pricebook_entries_account_id", deferrable: :deferred

    add_foreign_key :products, :user_profiles, column: :created_by, primary_key: :id, name: "fk_products_created_by", deferrable: :deferred
    add_foreign_key :products, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_products_updated_by", deferrable: :deferred

    add_foreign_key :activities, :user_profiles, column: :created_by, primary_key: :id, name: "fk_activities_created_by", deferrable: :deferred
    add_foreign_key :activities, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_activities_updated_by", deferrable: :deferred
    add_foreign_key :activities, :accounts, column: :account_id, primary_key: :id, name: "fk_activities_account_id", deferrable: :deferred
    add_foreign_key :activities, :contacts, column: :contact_id, primary_key: :id, name: "fk_activities_contact_id", deferrable: :deferred
    add_foreign_key :activities, :leads, column: :lead_id, primary_key: :id, name: "fk_activities_lead_id", deferrable: :deferred
    add_foreign_key :activities, :opportunities, column: :opportunity_id, primary_key: :id, name: "fk_activities_opportunity_id", deferrable: :deferred
    add_foreign_key :activities, :tickets, column: :ticket_id, primary_key: :id, name: "fk_activities_ticket_id", deferrable: :deferred
    add_foreign_key :activities, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_activities_owner_id", deferrable: :deferred

    add_foreign_key :tickets, :user_profiles, column: :created_by, primary_key: :id, name: "fk_tickets_created_by", deferrable: :deferred
    add_foreign_key :tickets, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_tickets_updated_by", deferrable: :deferred
    add_foreign_key :tickets, :ticket_statuses, column: :status_id, primary_key: :id, name: "fk_tickets_status_id", deferrable: :deferred
    add_foreign_key :tickets, :accounts, column: :account_id, primary_key: :id, name: "fk_tickets_account_id", deferrable: :deferred
    add_foreign_key :tickets, :contacts, column: :contact_id, primary_key: :id, name: "fk_tickets_contact_id", deferrable: :deferred
    add_foreign_key :tickets, :assets, column: :asset_id, primary_key: :id, name: "fk_tickets_asset_id", deferrable: :deferred
    add_foreign_key :tickets, :service_contracts, column: :service_contract_id, primary_key: :id, name: "fk_tickets_service_contract_id", deferrable: :deferred
    add_foreign_key :tickets, :slas, column: :sla_id, primary_key: :id, name: "fk_tickets_sla_id", deferrable: :deferred
    add_foreign_key :tickets, :user_profiles, column: :assigned_to, primary_key: :id, name: "fk_tickets_assigned_to", deferrable: :deferred
    add_foreign_key :tickets, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_tickets_owner_id", deferrable: :deferred

    add_foreign_key :ticket_statuses, :user_profiles, column: :created_by, primary_key: :id, name: "fk_ticket_statuses_created_by", deferrable: :deferred
    add_foreign_key :ticket_statuses, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_ticket_statuses_updated_by", deferrable: :deferred

    add_foreign_key :slas, :user_profiles, column: :created_by, primary_key: :id, name: "fk_slas_created_by", deferrable: :deferred
    add_foreign_key :slas, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_slas_updated_by", deferrable: :deferred

    add_foreign_key :knowledge_articles, :user_profiles, column: :created_by, primary_key: :id, name: "fk_knowledge_articles_created_by", deferrable: :deferred
    add_foreign_key :knowledge_articles, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_knowledge_articles_updated_by", deferrable: :deferred
    add_foreign_key :knowledge_articles, :user_profiles, column: :author_id, primary_key: :id, name: "fk_knowledge_articles_author_id", deferrable: :deferred

    add_foreign_key :ticket_knowledge_articles, :user_profiles, column: :created_by, primary_key: :id, name: "fk_ticket_knowledge_articles_created_by", deferrable: :deferred
    add_foreign_key :ticket_knowledge_articles, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_ticket_knowledge_articles_updated_by", deferrable: :deferred
    add_foreign_key :ticket_knowledge_articles, :tickets, column: :ticket_id, primary_key: :id, name: "fk_ticket_knowledge_articles_ticket_id", deferrable: :deferred, on_delete: :cascade
    add_foreign_key :ticket_knowledge_articles, :knowledge_articles, column: :article_id, primary_key: :id, name: "fk_ticket_knowledge_articles_article_id", deferrable: :deferred, on_delete: :cascade
    add_foreign_key :ticket_knowledge_articles, :user_profiles, column: :linked_by, primary_key: :id, name: "fk_ticket_knowledge_articles_linked_by", deferrable: :deferred

    add_foreign_key :service_contracts, :user_profiles, column: :created_by, primary_key: :id, name: "fk_service_contracts_created_by", deferrable: :deferred
    add_foreign_key :service_contracts, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_service_contracts_updated_by", deferrable: :deferred
    add_foreign_key :service_contracts, :accounts, column: :account_id, primary_key: :id, name: "fk_service_contracts_account_id", deferrable: :deferred
    add_foreign_key :service_contracts, :slas, column: :sla_id, primary_key: :id, name: "fk_service_contracts_sla_id", deferrable: :deferred
    add_foreign_key :service_contracts, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_service_contracts_owner_id", deferrable: :deferred

    add_foreign_key :assets, :user_profiles, column: :created_by, primary_key: :id, name: "fk_assets_created_by", deferrable: :deferred
    add_foreign_key :assets, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_assets_updated_by", deferrable: :deferred
    add_foreign_key :assets, :products, column: :product_id, primary_key: :id, name: "fk_assets_product_id", deferrable: :deferred
    add_foreign_key :assets, :accounts, column: :account_id, primary_key: :id, name: "fk_assets_account_id", deferrable: :deferred
    add_foreign_key :assets, :contacts, column: :contact_id, primary_key: :id, name: "fk_assets_contact_id", deferrable: :deferred
    add_foreign_key :assets, :user_profiles, column: :owner_id, primary_key: :id, name: "fk_assets_owner_id", deferrable: :deferred

    add_foreign_key :documents, :user_profiles, column: :created_by, primary_key: :id, name: "fk_documents_created_by", deferrable: :deferred
    add_foreign_key :documents, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_documents_updated_by", deferrable: :deferred
    add_foreign_key :documents, :user_profiles, column: :uploaded_by, primary_key: :id, name: "fk_documents_uploaded_by", deferrable: :deferred

    add_foreign_key :comments, :user_profiles, column: :created_by, primary_key: :id, name: "fk_comments_created_by", deferrable: :deferred
    add_foreign_key :comments, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_comments_updated_by", deferrable: :deferred
    add_foreign_key :comments, :user_profiles, column: :author_id, primary_key: :id, name: "fk_comments_author_id", deferrable: :deferred

    add_foreign_key :user_profiles, :user_profiles, column: :created_by, primary_key: :id, name: "fk_user_profiles_created_by", deferrable: :deferred
    add_foreign_key :user_profiles, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_user_profiles_updated_by", deferrable: :deferred
    add_foreign_key :user_profiles, :roles, column: :role_id, primary_key: :id, name: "fk_user_profiles_role_id", deferrable: :deferred
    add_foreign_key :user_profiles, :teams, column: :team_id, primary_key: :id, name: "fk_user_profiles_team_id", deferrable: :deferred

    add_foreign_key :roles, :user_profiles, column: :created_by, primary_key: :id, name: "fk_roles_created_by", deferrable: :deferred
    add_foreign_key :roles, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_roles_updated_by", deferrable: :deferred

    add_foreign_key :teams, :user_profiles, column: :created_by, primary_key: :id, name: "fk_teams_created_by", deferrable: :deferred
    add_foreign_key :teams, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_teams_updated_by", deferrable: :deferred
    add_foreign_key :teams, :user_profiles, column: :manager_id, primary_key: :id, name: "fk_teams_manager_id", deferrable: :deferred

    add_foreign_key :notifications, :user_profiles, column: :created_by, primary_key: :id, name: "fk_notifications_created_by", deferrable: :deferred
    add_foreign_key :notifications, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_notifications_updated_by", deferrable: :deferred
    add_foreign_key :notifications, :user_profiles, column: :user_id, primary_key: :id, name: "fk_notifications_user_id", deferrable: :deferred

    add_foreign_key :dashboard_configs, :user_profiles, column: :created_by, primary_key: :id, name: "fk_dashboard_configs_created_by", deferrable: :deferred
    add_foreign_key :dashboard_configs, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_dashboard_configs_updated_by", deferrable: :deferred
    add_foreign_key :dashboard_configs, :user_profiles, column: :user_id, primary_key: :id, name: "fk_dashboard_configs_user_id", deferrable: :deferred

    add_foreign_key :badges, :user_profiles, column: :created_by, primary_key: :id, name: "fk_badges_created_by", deferrable: :deferred
    add_foreign_key :badges, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_badges_updated_by", deferrable: :deferred

    add_foreign_key :user_badges, :user_profiles, column: :created_by, primary_key: :id, name: "fk_user_badges_created_by", deferrable: :deferred
    add_foreign_key :user_badges, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_user_badges_updated_by", deferrable: :deferred
    add_foreign_key :user_badges, :user_profiles, column: :user_id, primary_key: :id, name: "fk_user_badges_user_id", deferrable: :deferred, on_delete: :cascade
    add_foreign_key :user_badges, :badges, column: :badge_id, primary_key: :id, name: "fk_user_badges_badge_id", deferrable: :deferred, on_delete: :cascade

    add_foreign_key :challenges, :user_profiles, column: :created_by, primary_key: :id, name: "fk_challenges_created_by", deferrable: :deferred
    add_foreign_key :challenges, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_challenges_updated_by", deferrable: :deferred
    add_foreign_key :challenges, :user_profiles, column: :user_id, primary_key: :id, name: "fk_challenges_user_id", deferrable: :deferred
    add_foreign_key :challenges, :badges, column: :reward_badge_id, primary_key: :id, name: "fk_challenges_reward_badge_id", deferrable: :deferred

    add_foreign_key :streaks, :user_profiles, column: :created_by, primary_key: :id, name: "fk_streaks_created_by", deferrable: :deferred
    add_foreign_key :streaks, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_streaks_updated_by", deferrable: :deferred
    add_foreign_key :streaks, :user_profiles, column: :user_id, primary_key: :id, name: "fk_streaks_user_id", deferrable: :deferred

    add_foreign_key :personal_bests, :user_profiles, column: :created_by, primary_key: :id, name: "fk_personal_bests_created_by", deferrable: :deferred
    add_foreign_key :personal_bests, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_personal_bests_updated_by", deferrable: :deferred
    add_foreign_key :personal_bests, :user_profiles, column: :user_id, primary_key: :id, name: "fk_personal_bests_user_id", deferrable: :deferred

    add_foreign_key :audit_logs, :user_profiles, column: :created_by, primary_key: :id, name: "fk_audit_logs_created_by", deferrable: :deferred
    add_foreign_key :audit_logs, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_audit_logs_updated_by", deferrable: :deferred
    add_foreign_key :audit_logs, :user_profiles, column: :user_id, primary_key: :id, name: "fk_audit_logs_user_id", deferrable: :deferred

    add_foreign_key :data_source_configs, :user_profiles, column: :created_by, primary_key: :id, name: "fk_data_source_configs_created_by", deferrable: :deferred
    add_foreign_key :data_source_configs, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_data_source_configs_updated_by", deferrable: :deferred

    add_foreign_key :ai_provider_configs, :user_profiles, column: :created_by, primary_key: :id, name: "fk_ai_provider_configs_created_by", deferrable: :deferred
    add_foreign_key :ai_provider_configs, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_ai_provider_configs_updated_by", deferrable: :deferred

    add_foreign_key :level_definitions, :user_profiles, column: :created_by, primary_key: :id, name: "fk_level_definitions_created_by", deferrable: :deferred
    add_foreign_key :level_definitions, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_level_definitions_updated_by", deferrable: :deferred

    add_foreign_key :xp_events, :user_profiles, column: :created_by, primary_key: :id, name: "fk_xp_events_created_by", deferrable: :deferred
    add_foreign_key :xp_events, :user_profiles, column: :updated_by, primary_key: :id, name: "fk_xp_events_updated_by", deferrable: :deferred
  end
end
