/**
 * A21: Master label catalog for i18n.
 * Static UI labels + dynamic generation from ModelRegistry.
 */
import ModelRegistry from '../model/ModelRegistry';
import navigationItems from './navigation';

/**
 * Static UI labels — all hardcoded English strings across the app.
 */
export const STATIC_LABELS = {
  // Navigation
  'nav.accounts': 'Accounts',
  'nav.contacts': 'Contacts',
  'nav.leads': 'Leads',
  'nav.opportunities': 'Opportunities',
  'nav.quotes': 'Quotes',
  'nav.sales_orders': 'Sales Orders',
  'nav.invoices': 'Invoices',
  'nav.products': 'Products',
  'nav.activities': 'Activities',
  'nav.tickets': 'Tickets',
  'nav.knowledge': 'Knowledge',
  'nav.assets': 'Assets',
  'nav.slas': 'SLAs',
  'nav.contracts': 'Contracts',
  'nav.settings': 'Settings',
  'nav.navigation': 'Navigation',

  // Common UI buttons
  'ui.save': 'Save',
  'ui.saving': 'Saving...',
  'ui.cancel': 'Cancel',
  'ui.delete': 'Delete',
  'ui.deleting': 'Deleting...',
  'ui.edit': 'Edit',
  'ui.new': 'New',
  'ui.export': 'Export',
  'ui.close': 'Close',
  'ui.back': 'Back',
  'ui.convert': 'Convert',
  'ui.converting': 'Converting...',
  'ui.create': 'Create',
  'ui.creating': 'Creating...',
  'ui.add': 'Add',
  'ui.remove': 'Remove',
  'ui.sign_in': 'Sign In',
  'ui.sign_out': 'Sign Out',
  'ui.sign_in_google': 'Sign in with Google',
  'ui.save_changes': 'Save Changes',
  'ui.choose_file': 'Choose File',
  'ui.import': 'Import',
  'ui.add_new': 'Add New',
  'ui.view_all': 'View All',
  'ui.link': 'Link',
  'ui.unlink': 'Unlink',
  'ui.done': 'Done',
  'ui.skip': 'Skip',
  'ui.or': 'or',
  'ui.yes': 'Yes',
  'ui.no': 'No',
  'ui.active': 'Active',
  'ui.inactive': 'Inactive',
  'ui.actions': 'Actions',
  'ui.view_details': 'View details',
  'ui.ask': 'Ask',
  'ui.untitled': 'Untitled',
  'ui.import_csv': 'Import CSV',
  'ui.add_mapping': '+ Add Mapping',
  'ui.never': 'Never',
  'ui.current': 'Current',
  'ui.loading': 'Loading...',

  // Section headers
  'section.details': 'Details',
  'section.linked_records': 'Linked Records',
  'section.system_information': 'System Information',
  'section.required_information': 'Required Information',
  'section.field_mapping': 'Field Mapping',
  'section.line_items': 'Line Items',
  'section.hierarchy': 'Hierarchy',

  // Settings page
  'settings.title': 'Settings',
  'settings.appearance': 'Appearance',
  'settings.theme': 'Theme',
  'settings.light': 'Light',
  'settings.dark': 'Dark',
  'settings.system': 'System',

  // Notification preferences
  // List sorting (F62)
  'settings.list_sort.title': 'List Sorting',
  'settings.list_sort.description': 'Sets the order each list opens in. Clicking a column header still re-sorts that list for the current visit only.',
  'settings.list_sort.object': 'Object',
  'settings.list_sort.sort_by': 'Sort By',
  'settings.list_sort.direction': 'Direction',
  'settings.list_sort.sorted_field': 'Sorted Field',
  'settings.list_sort.by_number': 'Number',
  'settings.list_sort.by_name': 'Name',
  'settings.list_sort.ascending': 'Ascending',
  'settings.list_sort.descending': 'Descending',
  'settings.list_sort.saved': 'Sort order saved',
  'settings.list_sort.hidden': '{n} hidden',
  'settings.list_sort.total_hidden': '{n} hidden',
  'settings.list_sort.hidden_help': 'These records have no value for this field, so a sorted list leaves them out entirely.',
  'settings.list_sort.fix': 'Fix',
  'settings.list_sort.fixing': 'Fixing…',
  'settings.list_sort.fixed': 'Assigned numbers to {n} record(s)',
  'settings.list_sort.load_failed': 'Failed to load list sort settings',
  'settings.list_sort.save_failed': 'Failed to save sort order',
  'settings.list_sort.fix_failed': 'Failed to assign numbers',

  'settings.notifications.title': 'Notification Preferences',
  'settings.notifications.description': 'Choose which notifications you want to receive.',
  'settings.notifications.ticket_assigned': 'Ticket Assigned',
  'settings.notifications.sla_breach': 'SLA Breach',
  'settings.notifications.deal_stage_change': 'Deal Stage Change',
  'settings.notifications.mentioned_in_comment': 'Mentioned in Comment',
  'settings.notifications.lead_assigned': 'Lead Assigned',
  'settings.notifications.challenge_assigned': 'Challenge Assigned',
  'settings.notifications.badge_earned': 'Badge Earned',
  'settings.notifications.level_up': 'Level Up',
  'settings.notifications.personal_best': 'Personal Best',
  'settings.notifications.system': 'System Notifications',
  'settings.notifications.desktop_enabled': 'Desktop Browser Notifications',
  'settings.notifications.desktop_helper': 'Show native browser notifications when new notifications arrive.',

  // AI Provider
  'settings.ai.title': 'AI Provider',
  'settings.ai.add': 'Add Provider',
  'settings.ai.description': 'Configure an AI provider for the AI assistant. Only one provider can be active at a time. API keys are stored securely and only accessed server-side.',
  'settings.ai.empty': 'No AI providers configured. Click "Add Provider" to get started.',
  'settings.ai.provider': 'Provider',
  'settings.ai.model': 'Model',
  'settings.ai.status': 'Status',
  'settings.ai.api_key': 'API Key',
  'settings.ai.api_key_helper': 'Leave blank to keep current key',
  'settings.ai.endpoint': 'Endpoint URL (optional)',
  'settings.ai.endpoint_placeholder': 'Custom endpoint URL (leave blank for default)',
  'settings.ai.edit_title': 'Edit AI Provider',
  'settings.ai.add_title': 'Add AI Provider',

  // Ticket statuses
  'settings.ticket.title': 'Ticket Statuses',
  'settings.ticket.add': 'Add Status',
  'settings.ticket.description': 'Configure the available statuses for service tickets.',
  'settings.ticket.empty': 'No ticket statuses configured. Click "Add Status" to create one.',
  'settings.ticket.name': 'Name',
  'settings.ticket.order': 'Order',
  'settings.ticket.resolved': 'Resolved',
  'settings.ticket.closed': 'Closed',
  'settings.ticket.name_placeholder': 'Status name',
  'settings.ticket.name_required': 'Status name is required.',

  // Access control
  'settings.access.title': 'Access Control',
  'settings.access.description': 'Restrict application access to specific email addresses or domains. When the list is empty, any authenticated user can access the app.',
  'settings.access.type': 'Type',
  'settings.access.email': 'Email',
  'settings.access.domain': 'Domain',
  'settings.access.email_label': 'Email address',
  'settings.access.domain_label': 'Domain',
  'settings.access.email_placeholder': 'john@example.com',
  'settings.access.domain_placeholder': 'example.com',
  'settings.access.empty': 'No restrictions configured. All authenticated users can access the app.',
  'settings.access.invalid_email': 'Please enter a valid email address.',
  'settings.access.invalid_domain': 'Please enter a valid domain (e.g., example.com).',
  'settings.access.duplicate': 'This entry already exists.',

  // Data import
  'settings.import.title': 'Data Import',
  'settings.import.description': 'Import records from a CSV file into any object type. Select the target object and click Import to begin.',
  'settings.import.object_type': 'Object Type',

  // Data replication
  'settings.replication.title': 'Data Replication',
  'settings.replication.add': 'Add Source',
  'settings.replication.description': 'Replicate data from external web services into CRMThree. Configure a source per object type with field mappings, then run to import records.',
  'settings.replication.empty': 'No replication sources configured.',
  'settings.replication.object_type': 'Object Type',
  'settings.replication.url': 'Web Service URL',
  'settings.replication.last_run': 'Last Run',
  'settings.replication.last_result': 'Last Result',
  'settings.replication.run_tooltip': 'Run replication',
  'settings.replication.starting': 'Starting replication...',
  'settings.replication.edit_title': 'Edit Replication Source',
  'settings.replication.add_title': 'Add Replication Source',
  'settings.replication.request_body': 'Request Body (JSON)',
  'settings.replication.key_field': 'Key Field (CRM)',
  'settings.replication.key_field_helper': 'CRM field used to match existing records',
  'settings.replication.source_key': 'Source Key Field',
  'settings.replication.source_key_helper': 'Field in the web service response that maps to the key field',
  'settings.replication.delete_field': 'Delete Flag Field',
  'settings.replication.delete_field_helper': 'Source field that indicates the record should be skipped',
  'settings.replication.source_field': 'Source Field',
  'settings.replication.crm_field': 'CRM Field',
  'settings.replication.mapping_empty': 'No field mappings configured. Click + to add one.',

  // Data sources
  'settings.datasource.title': 'Data Sources',
  'settings.datasource.add': 'Add Data Source',
  'settings.datasource.description': 'Configure per-object data source routing. By default all objects use the local database.',
  'settings.datasource.empty': 'No custom data source configurations. All objects use the local database.',
  'settings.datasource.source': 'Source',
  'settings.datasource.endpoint': 'Endpoint URL',
  'settings.datasource.auth': 'Auth',
  'settings.datasource.edit_title': 'Edit Data Source',
  'settings.datasource.add_title': 'Add Data Source',
  'settings.datasource.source_type': 'Source Type',
  'settings.datasource.auth_type': 'Authentication Type',
  'settings.datasource.username': 'Username',
  'settings.datasource.password': 'Password',
  'settings.datasource.access_token': 'Access Token',
  'settings.datasource.header_name': 'Header Name',
  'settings.datasource.external_field': 'External Field',
  'settings.datasource.mapping_helper': 'Map external system field names to CRM field names.',

  // Language management
  'settings.language.title': 'Language Management',
  'settings.language.add': 'Add Language',
  'settings.language.description': 'Manage UI translations. Add languages and translate all labels using AI or manually.',
  'settings.language.empty': 'No languages configured. Click "Add Language" to get started.',
  'settings.language.language': 'Language',
  'settings.language.code': 'Code',
  'settings.language.translated': 'Labels Translated',
  'settings.language.manage': 'Manage',
  'settings.language.add_title': 'Add Language',
  'settings.language.select': 'Select a language',
  'settings.language.manage_title': 'Manage Translations',
  'settings.language.search': 'Filter labels...',
  'settings.language.key': 'Label Key',
  'settings.language.english': 'English',
  'settings.language.ai_translate': 'AI Translate All',
  'settings.language.translating': 'Translating...',
  'settings.language.all': 'All',
  'settings.language.category_nav': 'Navigation',
  'settings.language.category_fields': 'Fields',
  'settings.language.category_enums': 'Enums',
  'settings.language.category_ui': 'UI',
  'settings.language.category_other': 'Other',

  // Dashboard
  'dashboard.welcome_back': 'Welcome back',
  'dashboard.configure_widgets': 'Configure widgets',
  'dashboard.show_hide_widgets': 'Show / Hide Widgets',
  'dashboard.pipeline_value': 'Pipeline Value',
  'dashboard.open_opportunities': 'Open Opportunities',
  'dashboard.open_tickets': 'Open Tickets',
  'dashboard.open_leads': 'Open Leads',
  'dashboard.activities_this_week': 'Activities This Week',
  'dashboard.ai_summary': 'AI Priority Summary',
  'dashboard.ai_summary_placeholder': 'Your personalized AI-powered priority summary will appear here in a future update.',
  'dashboard.opp_by_stage': 'Opportunities by Stage',
  'dashboard.tickets_by_priority': 'Tickets by Priority',
  'dashboard.activity_trend': 'Activity Trend',
  'dashboard.revenue_by_status': 'Revenue by Status',
  'dashboard.total': 'total',
  'dashboard.conversion_rate': 'conversion rate',
  'dashboard.open_opportunities_subtitle': 'open opportunities',

  // Quick actions
  'action.log_call': 'Log Call',
  'action.log_email': 'Log Email',
  'action.log_meeting': 'Log Meeting',
  'action.new_task': 'New Task',
  'action.new_quote': 'New Quote',
  'action.new_sales_order': 'New Sales Order',
  'action.new_invoice': 'New Invoice',

  // Profile / Menu
  'menu.profile': 'Profile',
  'menu.sign_out': 'Sign Out',
  'menu.notifications': 'Notifications',
  'menu.no_notifications': 'No notifications',
  'menu.mark_all_read': 'Mark all as read',
  'menu.badges': 'Badges & Achievements',

  // AI search
  'search.placeholder': 'Ask AI or search across all records (Ctrl+K)',
  'search.thinking': 'Thinking...',
  'search.ai_searching': 'AI is searching...',
  'search.searching': 'Searching...',
  'search.no_results': 'No results found',
  'search.ai_results': 'AI Search Results',

  // AI Briefing
  'ai.briefing': 'AI Briefing',
  'ai.generate': 'Generate Briefing',
  'ai.regenerate': 'Regenerate',
  'ai.expand': 'Expand',
  'ai.collapse': 'Collapse',
  'ai.generating': 'Generating briefing...',

  // Delete dialog
  'dialog.delete_title': 'Delete',
  'dialog.delete_confirm': 'Are you sure you want to delete',
  'dialog.delete_undone': 'This action cannot be undone.',

  // Lead convert dialog
  'dialog.convert_lead': 'Convert Lead',
  'dialog.convert_description': 'Converting this lead will create the following records:',
  'dialog.contact': 'Contact',
  'dialog.account': 'Account',
  'dialog.account_name': 'Account Name',
  'dialog.account_name_required': 'Account name is required.',
  'dialog.opportunity': 'Opportunity',
  'dialog.create_opportunity': 'Create an opportunity',
  'dialog.opportunity_name': 'Opportunity Name',
  'dialog.opportunity_name_required': 'Opportunity name is required when creating an opportunity.',
  'dialog.conversion_failed': 'Conversion failed. Please try again.',
  'dialog.already_converted': 'Already converted',
  'dialog.convert_tooltip': 'Convert to Contact, Account & Opportunity',

  // Document convert dialog
  'dialog.create_from': 'Create {target} from {source}',
  'dialog.doc_convert_description': 'This will create a new {target} based on this {source}.',
  'dialog.source': 'Source',
  'dialog.what_created': 'What will be created',
  'dialog.line_items_copied': 'line items will be copied',
  'dialog.no_line_items': 'No line items to copy',

  // CSV import dialog
  'dialog.import_title': 'Import {label} from CSV',
  'dialog.select_csv': 'Select a CSV file to import',
  'dialog.csv_empty': 'CSV file is empty or has no data rows.',
  'dialog.csv_parse_failed': 'Failed to parse CSV file: ',
  'dialog.field_mapping_count': 'Field Mapping ({mapped} of {total} mapped)',
  'dialog.preview_title': 'Preview',
  'dialog.import_complete': 'Import complete:',
  'dialog.created': 'created',
  'dialog.skipped': 'skipped',
  'dialog.updated': 'updated',
  'dialog.errors': 'errors',
  'dialog.importing': 'Importing records...',
  'dialog.import_records': 'Import {count} Records',

  // Line items
  'line_items.title': 'Line Items',
  'line_items.item_number': 'Item #',
  'line_items.product': 'Product',
  'line_items.quantity': 'Quantity',
  'line_items.net_price': 'Net Price',
  'line_items.discount': 'Discount %',
  'line_items.net_value': 'Net Value',
  'line_items.total': 'Total:',
  'line_items.select_product': 'Select product',

  // Profile page
  'profile.title': 'Profile',
  'profile.language': 'Language',
  'profile.language_helper': 'Select your preferred UI language.',
  'profile.placeholder': 'User profile, gamification stats, and trophy case will appear here.',

  // Login errors
  'login.title': 'CRM THREE',
  'login.subtitle': 'Sign in to continue',
  'login.email': 'Email',
  'login.password': 'Password',
  'login.error.invalid_email': 'Invalid email address.',
  'login.error.disabled': 'This account has been disabled.',
  'login.error.invalid_credentials': 'Invalid email or password.',
  'login.error.too_many_attempts': 'Too many sign-in attempts. Please try again later.',
  'login.error.popup_closed': 'Sign-in cancelled.',
  'login.error.generic': 'An error occurred during sign-in.',

  // App-level
  'app.loading_profile': 'Loading your profile...',
  'app.not_authorized': 'Your email address is not authorized to access this application. Please contact an administrator.',
  'app.deactivated': 'Your account has been deactivated. Please contact an administrator.',
  'app.not_provisioned': 'Your account has not been provisioned yet. Please contact an administrator to set up your user profile.',

  // Misc
  'misc.no_linked_records': 'No linked records.',
  'misc.failed_save': 'Failed to save changes.',
  'misc.failed_load': 'Failed to load records.',
  'misc.failed_save_prefs': 'Failed to save preferences.',

  // Form
  'form.show_fewer': 'Show fewer fields',
  'form.show_more': 'Show all fields',
  'form.save_error': 'An error occurred while saving.',
};

/**
 * Generate complete label catalog: static + dynamic from data model.
 * Dynamic keys include field labels, enum values, object types, and relationships.
 */
export function getAllLabels() {
  const labels = { ...STATIC_LABELS };

  // Object type labels from navigation
  navigationItems.forEach((item) => {
    labels[`object.${item.objectType}`] = item.label;
  });

  // Field labels + enum values from all object types
  ModelRegistry.getObjectTypes().forEach((objType) => {
    try {
      const fields = ModelRegistry.getSpecificFields(objType);
      fields.forEach((field) => {
        const label = field.description ||
          field.name.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
        labels[`field.${objType}.${field.name}`] = label;

        if (field.type === 'enum' && field.values) {
          field.values.forEach((v) => {
            labels[`enum.${v}`] = v;
          });
        }
      });
    } catch { /* skip invalid types */ }
  });

  // Common fields
  ModelRegistry.getCommonFields().forEach((field) => {
    const label = field.description ||
      field.name.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
    labels[`field._common.${field.name}`] = label;
  });

  // Relationship names
  ModelRegistry.getObjectTypes().forEach((objType) => {
    try {
      const rels = ModelRegistry.getRelationships(objType);
      rels.forEach((rel) => {
        const formatted = rel.name.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
        labels[`rel.${rel.name}`] = formatted;
      });
    } catch { /* skip */ }
  });

  return labels;
}
