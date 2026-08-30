import BusinessIcon from '@mui/icons-material/Business';
import PeopleIcon from '@mui/icons-material/People';
import PersonSearchIcon from '@mui/icons-material/PersonSearch';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import RequestQuoteIcon from '@mui/icons-material/RequestQuote';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import ReceiptIcon from '@mui/icons-material/Receipt';
import InventoryIcon from '@mui/icons-material/Inventory';
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import DevicesIcon from '@mui/icons-material/Devices';
import PhoneInTalkIcon from '@mui/icons-material/PhoneInTalk';
import GavelIcon from '@mui/icons-material/Gavel';
import HandshakeIcon from '@mui/icons-material/Handshake';
import MeetingRoomIcon from '@mui/icons-material/MeetingRoom';
import SupportAgentIcon from '@mui/icons-material/SupportAgent';

const navigationItems = [
  { label: 'Accounts', path: '/accounts', icon: BusinessIcon, objectType: 'Account' },
  { label: 'Contacts', path: '/contacts', icon: PeopleIcon, objectType: 'Contact' },
  { label: 'Leads', path: '/leads', icon: PersonSearchIcon, objectType: 'Lead' },
  { label: 'Opportunities', path: '/opportunities', icon: TrendingUpIcon, objectType: 'Opportunity' },
  { label: 'Deal Rooms', path: '/deal-rooms', icon: MeetingRoomIcon, objectType: 'DealRoom' },
  { label: 'Quotes', path: '/quotes', icon: RequestQuoteIcon, objectType: 'Quotation' },
  { label: 'Sales Orders', path: '/sales-orders', icon: ShoppingCartIcon, objectType: 'SalesOrder' },
  { label: 'Invoices', path: '/invoices', icon: ReceiptIcon, objectType: 'Invoice' },
  { label: 'Products', path: '/products', icon: InventoryIcon, objectType: 'Product' },
  { label: 'Activities', path: '/activities', icon: PhoneInTalkIcon, objectType: 'Activity' },
  { label: 'Tickets', path: '/tickets', icon: ConfirmationNumberIcon, objectType: 'Ticket' },
  { label: 'Case Rooms', path: '/case-rooms', icon: SupportAgentIcon, objectType: 'CaseRoom' },
  { label: 'Knowledge', path: '/knowledge', icon: MenuBookIcon, objectType: 'KnowledgeArticle' },
  { label: 'Assets', path: '/assets', icon: DevicesIcon, objectType: 'Asset' },
  { label: 'SLAs', path: '/slas', icon: GavelIcon, objectType: 'SLA' },
  { label: 'Contracts', path: '/contracts', icon: HandshakeIcon, objectType: 'ServiceContract' },
];

// Child object types that need URL routing but don't appear in the Ribbon
const childSlugMap = {
  LineItem: 'line-items',
  Document: 'documents',
  Comment: 'comments',
};

/**
 * Resolves a URL slug (e.g., "accounts") to a ModelRegistry objectType (e.g., "Account").
 */
// Slugs that list records of a different object type (e.g., Case Rooms → Tickets)
const slugObjectOverrides = {
  'case-rooms': 'Ticket',
};

export function resolveObjectType(slug) {
  if (slugObjectOverrides[slug]) return slugObjectOverrides[slug];
  const item = navigationItems.find((n) => n.path === `/${slug}`);
  if (item) return item.objectType;
  const entry = Object.entries(childSlugMap).find(([, s]) => s === slug);
  return entry ? entry[0] : null;
}

/**
 * Resolves a ModelRegistry objectType (e.g., "Account") to a URL slug (e.g., "accounts").
 */
export function resolveSlug(objectType) {
  const item = navigationItems.find((n) => n.objectType === objectType);
  if (item) return item.path.slice(1);
  return childSlugMap[objectType] || null;
}

export default navigationItems;
