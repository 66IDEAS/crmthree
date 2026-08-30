import { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import Snackbar from '@mui/material/Snackbar';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';
import TransformIcon from '@mui/icons-material/Transform';
import DescriptionIcon from '@mui/icons-material/Description';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import ReceiptIcon from '@mui/icons-material/Receipt';
import MeetingRoomIcon from '@mui/icons-material/MeetingRoom';
import SupportAgentIcon from '@mui/icons-material/SupportAgent';
import { useParams, useNavigate } from 'react-router';
import { resolveObjectType, resolveSlug } from '../config/navigation';
import { getObjectLabel, getDisplayName } from '../utils/fieldUtils';
import ModelRegistry from '../model/ModelRegistry';
import DataService from '../services/DataService';
import { useRecord, useList, useMutation } from '../hooks/useDataService';
import LoadingSpinner from '../components/common/LoadingSpinner';
import RecordDetailHeader from '../components/records/RecordDetailHeader';
import RecordDetailsCard from '../components/records/RecordDetailsCard';
import QuickActionBar from '../components/records/QuickActionBar';
import LinkedRecordsSection from '../components/records/LinkedRecordsSection';
import HierarchyTree from '../components/records/HierarchyTree';
import AiRecordSummary from '../components/records/AiRecordSummary';
import DeleteConfirmDialog from '../components/records/DeleteConfirmDialog';
import LeadConvertDialog from '../components/records/LeadConvertDialog';
import DocumentConvertDialog from '../components/records/DocumentConvertDialog';
import { useNavigationHistory } from '../contexts/NavigationHistoryContext';
import { useAuth } from '../contexts/AuthContext';
import useRecordLock from '../hooks/useRecordLock';
import { acquireLock, releaseLock, heartbeat } from '../services/RecordLockService';
import { t } from '../services/TranslationService';

/** UX32: Document-to-document conversion configurations */
const DOCUMENT_CONVERSIONS = {
  Opportunity: [
    {
      targetType: 'Quotation',
      label: 'Create Quotation',
      icon: DescriptionIcon,
      fieldMap: { account_id: 'account_id', currency: 'currency', owner_id: 'owner_id' },
      setFields: { opportunity_id: (src) => src.id, status: 'Draft' },
      copyLineItems: true,
    },
    {
      targetType: 'SalesOrder',
      label: 'Create Sales Order',
      icon: ShoppingCartIcon,
      fieldMap: { account_id: 'account_id', currency: 'currency', owner_id: 'owner_id' },
      setFields: {
        opportunity_id: (src) => src.id,
        status: 'Draft',
        order_date: () => new Date().toISOString().split('T')[0],
      },
      copyLineItems: true,
    },
  ],
  Quotation: [
    {
      targetType: 'SalesOrder',
      label: 'Create Sales Order',
      icon: ShoppingCartIcon,
      fieldMap: {
        account_id: 'account_id',
        contact_id: 'contact_id',
        opportunity_id: 'opportunity_id',
        currency: 'currency',
        owner_id: 'owner_id',
      },
      setFields: {
        quotation_id: (src) => src.id,
        status: 'Draft',
        order_date: () => new Date().toISOString().split('T')[0],
      },
      copyLineItems: true,
    },
  ],
  SalesOrder: [
    {
      targetType: 'Invoice',
      label: 'Create Invoice',
      icon: ReceiptIcon,
      fieldMap: {
        account_id: 'account_id',
        contact_id: 'contact_id',
        currency: 'currency',
        owner_id: 'owner_id',
      },
      setFields: {
        sales_order_id: (src) => src.id,
        status: 'Draft',
        invoice_date: () => new Date().toISOString().split('T')[0],
        due_date: () => {
          const d = new Date();
          d.setDate(d.getDate() + 30);
          return d.toISOString().split('T')[0];
        },
      },
      copyLineItems: true,
    },
  ],
};

export default function ObjectDetailPage() {
  const { objectType: slug, id } = useParams();
  const objectType = resolveObjectType(slug);

  if (!objectType) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{t('ui.unknown_object_type', 'Unknown object type')}: {slug}</Alert>
      </Box>
    );
  }

  return <DetailView key={`${objectType}-${id}`} objectType={objectType} slug={slug} id={id} />;
}

function DetailView({ objectType, slug, id }) {
  const navigate = useNavigate();
  const { userProfile } = useAuth();
  const { data: record, loading, error, refetch } = useRecord(objectType, id);
  const { remove, loading: deleteLoading } = useMutation(objectType);
  const { updateCurrentLabel } = useNavigationHistory();
  const [editing, setEditing] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [convertOpen, setConvertOpen] = useState(false);
  const [activeConversion, setActiveConversion] = useState(null);
  const [accountName, setAccountName] = useState('');
  const [lockSnackbar, setLockSnackbar] = useState('');
  const heartbeatRef = useRef(null);

  // F61: Pessimistic record locking
  const { lock } = useRecordLock(objectType, id);
  const isLockedByOther = lock && lock.locked_by !== userProfile?.id;

  const getUserDisplayName = useCallback(() => {
    if (!userProfile) return 'User';
    return [userProfile.first_name, userProfile.last_name].filter(Boolean).join(' ') || userProfile.email || 'User';
  }, [userProfile]);

  const handleEdit = useCallback(async () => {
    if (!userProfile?.id) return;
    const result = await acquireLock(objectType, id, userProfile.id, getUserDisplayName());
    if (!result.success) {
      setLockSnackbar(t('lock.locked_by', '{name} is currently editing this record.').replace('{name}', result.lockedBy));
      return;
    }
    setEditing(true);
    // Start heartbeat
    heartbeatRef.current = setInterval(() => {
      heartbeat(objectType, id, userProfile.id);
    }, 5 * 60 * 1000);
  }, [objectType, id, userProfile, getUserDisplayName]);

  const handleEditToggle = useCallback((value) => {
    if (!value) {
      // Releasing edit mode — release the lock
      if (userProfile?.id) {
        releaseLock(objectType, id, userProfile.id);
      }
      if (heartbeatRef.current) {
        clearInterval(heartbeatRef.current);
        heartbeatRef.current = null;
      }
    }
    setEditing(value);
  }, [objectType, id, userProfile]);

  // Release lock on unmount or navigation
  useEffect(() => {
    const handleBeforeUnload = () => {
      if (editing && userProfile?.id) {
        releaseLock(objectType, id, userProfile.id);
      }
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
      // Also release on component unmount (navigation within the app)
      if (editing && userProfile?.id) {
        releaseLock(objectType, id, userProfile.id);
      }
      if (heartbeatRef.current) {
        clearInterval(heartbeatRef.current);
      }
    };
  }, [editing, objectType, id, userProfile]);

  // F33: Check if a Deal Room exists for this Opportunity
  const isOpportunity = objectType === 'Opportunity';
  const dealRoomOpts = useMemo(
    () => isOpportunity
      ? { filters: [{ field: 'opportunity_id', op: '==', value: id }], pageSize: 1 }
      : {},
    [isOpportunity, id]
  );
  const { data: dealRooms } = useList(isOpportunity ? 'DealRoom' : null, isOpportunity ? dealRoomOpts : {});
  const existingDealRoom = isOpportunity ? dealRooms?.[0] : null;

  const label = getObjectLabel(objectType);
  const singularLabel = label.replace(/s$/, '');

  const fields = ModelRegistry.getSpecificFields(objectType);
  const baseName = record ? getDisplayName(record, fields) : null;

  // For document-type objects without a name field, enrich headline with account name
  useEffect(() => {
    if (record?.account_id && !fields.find((f) => ['name', 'name1', 'first_name', 'title', 'subject'].includes(f.name))) {
      DataService.getById('Account', record.account_id)
        .then((acc) => {
          if (acc) {
            const accFields = ModelRegistry.getSpecificFields('Account');
            setAccountName(getDisplayName(acc, accFields));
          }
        })
        .catch(() => {});
    }
  }, [record?.account_id, fields]);

  const recordName = baseName && accountName ? `${baseName} (${accountName})` : baseName;

  useEffect(() => {
    if (recordName) updateCurrentLabel(recordName);
  }, [recordName, updateCurrentLabel]);

  if (loading) return <LoadingSpinner />;

  if (error) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="error">{error.message || t('ui.failed_to_load_record', 'Failed to load record.')}</Alert>
      </Box>
    );
  }

  if (!record) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{singularLabel} {t('ui.not_found', 'not found')}.</Alert>
      </Box>
    );
  }

  const handleDelete = async () => {
    try {
      await remove(id);
      navigate(`/${slug}`);
    } catch {
      // Error displayed via useMutation
    }
  };

  const handleConverted = ({ opportunity, contact }) => {
    setConvertOpen(false);
    // Navigate to the new opportunity, or the new contact if no opportunity was created
    if (opportunity) {
      const oppSlug = resolveSlug('Opportunity');
      navigate(`/${oppSlug}/${opportunity.id}`);
    } else if (contact) {
      const contactSlug = resolveSlug('Contact');
      navigate(`/${contactSlug}/${contact.id}`);
    } else {
      refetch();
    }
  };

  // Lead-specific: Convert button
  const isLead = objectType === 'Lead';
  const isConverted = isLead && record.status === 'Converted';

  // Document conversion buttons (F4-F7)
  const conversions = DOCUMENT_CONVERSIONS[objectType] || [];

  const extraActions = (
    <>
      {isLead && (
        <Tooltip title={isConverted ? t('dialog.already_converted', 'Already converted') : t('dialog.convert_tooltip', 'Convert to Contact, Account & Opportunity')}>
          <span>
            <Button
              variant="outlined"
              size="small"
              startIcon={<TransformIcon />}
              onClick={() => setConvertOpen(true)}
              disabled={isConverted}
            >
              {t('ui.convert', 'Convert')}
            </Button>
          </span>
        </Tooltip>
      )}
      {conversions.map((conv) => {
        const Icon = conv.icon;
        return (
          <Tooltip key={conv.targetType} title={conv.label}>
            <Button
              variant="outlined"
              size="small"
              startIcon={<Icon />}
              onClick={() => setActiveConversion(conv)}
            >
              {conv.label}
            </Button>
          </Tooltip>
        );
      })}
      {isOpportunity && (
        existingDealRoom ? (
          <Button
            variant="outlined"
            size="small"
            startIcon={<MeetingRoomIcon />}
            onClick={() => navigate(`/deal-rooms/${existingDealRoom.id}`)}
          >
            {t('action.open_deal_room', 'Open Deal Room')}
          </Button>
        ) : (
          <Button
            variant="outlined"
            size="small"
            startIcon={<MeetingRoomIcon />}
            onClick={() => {
              const params = new URLSearchParams({
                opportunity_id: id,
                '_prefill_name': baseName || '',
              });
              navigate(`/deal-rooms/new?${params.toString()}`);
            }}
          >
            {t('action.create_deal_room', 'Create Deal Room')}
          </Button>
        )
      )}
      {objectType === 'Ticket' && (
        <Button
          variant="outlined"
          size="small"
          startIcon={<SupportAgentIcon />}
          onClick={() => navigate(`/case-rooms/${id}`)}
        >
          {t('action.open_case_room', 'Open Case Room')}
        </Button>
      )}
    </>
  );

  return (
    <Box>
      <RecordDetailHeader
        objectType={objectType}
        slug={slug}
        record={record}
        onEdit={handleEdit}
        onDelete={() => setDeleteOpen(true)}
        extraActions={extraActions}
        displayNameOverride={recordName}
        lock={isLockedByOther ? lock : null}
      />

      <AiRecordSummary
        objectType={objectType}
        record={record}
      />

      <QuickActionBar
        objectType={objectType}
        record={record}
        onConvert={(targetType) => {
          const conv = conversions.find((c) => c.targetType === targetType);
          if (conv) setActiveConversion(conv);
        }}
        onLeadConvert={isLead ? () => setConvertOpen(true) : undefined}
      />

      <RecordDetailsCard
        objectType={objectType}
        record={record}
        onRefetch={refetch}
        editing={editing}
        onEditToggle={handleEditToggle}
      />

      <HierarchyTree
        objectType={objectType}
        slug={slug}
        record={record}
      />

      <LinkedRecordsSection
        objectType={objectType}
        recordId={id}
        record={record}
      />

      <DeleteConfirmDialog
        open={deleteOpen}
        onCancel={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
        objectTypeLabel={singularLabel}
        recordName={recordName}
        loading={deleteLoading}
      />

      {isLead && (
        <LeadConvertDialog
          open={convertOpen}
          onClose={() => setConvertOpen(false)}
          lead={record}
          onConverted={handleConverted}
        />
      )}

      {activeConversion && (
        <DocumentConvertDialog
          open={!!activeConversion}
          onClose={() => setActiveConversion(null)}
          sourceRecord={record}
          sourceType={objectType}
          targetType={activeConversion.targetType}
          fieldMap={activeConversion.fieldMap}
          setFields={activeConversion.setFields}
          copyLineItems={activeConversion.copyLineItems}
          onConverted={(newRecord) => {
            setActiveConversion(null);
            const targetSlug = resolveSlug(activeConversion.targetType);
            navigate(`/${targetSlug}/${newRecord.id}`);
          }}
        />
      )}

      <Snackbar
        open={!!lockSnackbar}
        autoHideDuration={4000}
        onClose={() => setLockSnackbar('')}
        message={lockSnackbar}
      />
    </Box>
  );
}
