/**
 * Maps object type names from the data model to Firestore collection names.
 * Convention: camelCase plural form.
 */
const collectionMap = {
  Account: 'accounts',
  Contact: 'contacts',
  ContactAccount: 'contactAccounts',
  Lead: 'leads',
  Opportunity: 'opportunities',
  OpportunityContact: 'opportunityContacts',
  DealRoom: 'dealRooms',
  PipelineStage: 'pipelineStages',
  Quotation: 'quotations',
  SalesOrder: 'salesOrders',
  Invoice: 'invoices',
  LineItem: 'lineItems',
  PricebookEntry: 'pricebookEntries',
  Product: 'products',
  Activity: 'activities',
  Ticket: 'tickets',
  TicketStatus: 'ticketStatuses',
  SLA: 'slas',
  KnowledgeArticle: 'knowledgeArticles',
  TicketKnowledgeArticle: 'ticketKnowledgeArticles',
  ServiceContract: 'serviceContracts',
  Asset: 'assets',
  Document: 'documents',
  Comment: 'comments',
  UserProfile: 'userProfiles',
  Role: 'roles',
  Team: 'teams',
  Notification: 'notifications',
  DashboardConfig: 'dashboardConfigs',
  Badge: 'badges',
  UserBadge: 'userBadges',
  Challenge: 'challenges',
  Streak: 'streaks',
  PersonalBest: 'personalBests',
  AuditLog: 'auditLogs',
  DataSourceConfig: 'dataSourceConfigs',
  AIProviderConfig: 'aiProviderConfigs',
  LevelDefinition: 'levelDefinitions',
  XPEvent: 'xpEvents',
  ReplicationConfig: 'replicationConfigs',
  RecordLock: 'recordLocks',
};

/**
 * Returns the Firestore collection name for a given object type.
 * Throws if the object type is not mapped.
 */
export function getCollectionName(objectType) {
  const name = collectionMap[objectType];
  if (!name) throw new Error(`No collection mapping for object type: ${objectType}`);
  return name;
}

export default collectionMap;
