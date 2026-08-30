import { useEffect, useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Alert from '@mui/material/Alert';
import Grid from '@mui/material/Grid';
import Paper from '@mui/material/Paper';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import { useParams, useNavigate } from 'react-router';
import { useUI } from '../contexts/UIContext';
import { useNavigationHistory } from '../contexts/NavigationHistoryContext';
import { useRecord, useList } from '../hooks/useDataService';
import ModelRegistry from '../model/ModelRegistry';
import { getDisplayName, getAutoNumberField, formatAutoNumber } from '../utils/fieldUtils';
import LoadingSpinner from '../components/common/LoadingSpinner';
import AiRecordSummary from '../components/records/AiRecordSummary';
import LinkedRecordCard from '../components/records/LinkedRecordCard';
import FieldRenderer from '../components/fields/FieldRenderer';
import ActivityTimeline from '../components/dealroom/ActivityTimeline';
import CommentThread from '../components/dealroom/CommentThread';
import CaseRoomQuickActions from '../components/caseroom/CaseRoomQuickActions';
import { t } from '../services/TranslationService';

const PRIORITY_COLORS = {
  Low: 'info',
  Medium: 'warning',
  High: 'error',
  Critical: 'error',
};

function TicketInfoCard({ ticket, statusName }) {
  if (!ticket) return null;

  const fields = ModelRegistry.getSpecificFields('Ticket');

  const metrics = [
    { name: 'priority', label: t('field.Ticket.priority', 'Priority') },
    { name: 'category', label: t('field.Ticket.category', 'Category') },
    { name: 'first_response_at', label: t('field.Ticket.first_response_at', 'First Response') },
    { name: 'resolved_at', label: t('field.Ticket.resolved_at', 'Resolved At') },
    { name: 'closed_at', label: t('field.Ticket.closed_at', 'Closed At') },
    { name: 'sla_response_deadline', label: t('field.Ticket.sla_response_deadline', 'SLA Response Deadline') },
    { name: 'sla_resolution_deadline', label: t('field.Ticket.sla_resolution_deadline', 'SLA Resolution Deadline') },
  ];

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>
        {t('section.ticket_info', 'Ticket Info')}
      </Typography>

      {statusName && (
        <Box sx={{ mb: 1.5 }}>
          <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 0.25 }}>
            {t('field.Ticket.status_id', 'Status')}
          </Typography>
          <Typography variant="body2">{statusName}</Typography>
        </Box>
      )}

      {metrics.map(({ name, label }) => {
        const field = fields.find((f) => f.name === name);
        const value = ticket[name];
        if (!field || value === null || value === undefined || value === '') return null;
        return (
          <Box key={name} sx={{ mb: 1.5 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 0.25 }}>
              {label}
            </Typography>
            <FieldRenderer field={field} value={value} />
          </Box>
        );
      })}

      {/* Reference fields */}
      {['account_id', 'contact_id', 'assigned_to', 'owner_id'].map((refName) => {
        const field = fields.find((f) => f.name === refName);
        const value = ticket[refName];
        if (!field || !value) return null;
        return (
          <Box key={refName} sx={{ mb: 1.5 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 0.25 }}>
              {t(`field.Ticket.${refName}`, field.description || refName)}
            </Typography>
            <FieldRenderer field={field} value={value} />
          </Box>
        );
      })}
    </Paper>
  );
}

export default function CaseRoomPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { isMobile } = useUI();
  const { updateCurrentLabel } = useNavigationHistory();

  // Load ticket
  const { data: ticket, loading: ticketLoading, error: ticketError, refetch } = useRecord('Ticket', id);

  // Load ticket statuses
  const statusOpts = useMemo(() => ({ pageSize: 100 }), []);
  const { data: ticketStatuses } = useList('TicketStatus', statusOpts);
  const sortedStatuses = useMemo(
    () => [...(ticketStatuses || [])].sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0)),
    [ticketStatuses]
  );
  const currentStatus = sortedStatuses.find((s) => s.id === ticket?.status_id);

  // Fields for display
  const fields = ModelRegistry.getSpecificFields('Ticket');
  const autoNumberField = getAutoNumberField(fields);
  const displayName = ticket ? (ticket.subject || getDisplayName(ticket, fields)) : '';

  // Update breadcrumb
  useEffect(() => {
    if (displayName) updateCurrentLabel(displayName);
  }, [displayName, updateCurrentLabel]);

  if (ticketLoading) return <LoadingSpinner />;

  if (ticketError) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="error">{ticketError.message || t('ui.failed_to_load_record', 'Failed to load record.')}</Alert>
      </Box>
    );
  }

  if (!ticket) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{t('caseroom.not_found', 'Ticket not found.')}</Alert>
      </Box>
    );
  }

  const isClosed = currentStatus?.name?.toLowerCase().includes('closed');

  return (
    <Box>
      {/* Sticky Header */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          mb: 2,
          flexWrap: 'wrap',
          position: 'sticky',
          top: 0,
          zIndex: 2,
          bgcolor: 'background.default',
          py: 1,
          px: 2,
        }}
      >
        <Tooltip title={t('ui.back', 'Back')}>
          <IconButton onClick={() => navigate(-1)} size="small">
            <ArrowBackIcon />
          </IconButton>
        </Tooltip>
        <Typography variant={isMobile ? 'h6' : 'h5'} sx={{ fontWeight: 700 }} noWrap>
          {displayName}
        </Typography>
        {autoNumberField && ticket[autoNumberField.name] && (
          <Chip
            label={formatAutoNumber(ticket[autoNumberField.name])}
            size="small"
            variant="outlined"
          />
        )}
        {currentStatus && (
          <Chip
            label={currentStatus.name}
            size="small"
            color={isClosed ? 'default' : 'primary'}
          />
        )}
        {ticket.priority && (
          <Chip
            label={ticket.priority}
            size="small"
            color={PRIORITY_COLORS[ticket.priority] || 'default'}
          />
        )}
        <Box sx={{ flex: 1 }} />
        <Button
          variant="outlined"
          size="small"
          startIcon={<OpenInNewIcon />}
          onClick={() => navigate(`/tickets/${ticket.id}`)}
        >
          {t('action.view_ticket', 'View Ticket')}
        </Button>
      </Box>

      {/* AI Summary */}
      <Box sx={{ px: 2, mb: 1 }}>
        <AiRecordSummary objectType="Ticket" record={ticket} />
      </Box>

      {/* Quick Actions */}
      {!isClosed && (
        <CaseRoomQuickActions
          ticket={ticket}
          ticketStatuses={sortedStatuses}
          onRefetch={refetch}
        />
      )}

      {/* Two-column layout */}
      <Grid container spacing={2} sx={{ px: 2, pb: 3 }}>
        {/* Left column: Timeline + Comments */}
        <Grid size={{ xs: 12, md: 8 }}>
          <ActivityTimeline ticketId={ticket.id} />
          <Box sx={{ mt: 2 }}>
            <CommentThread parentType="Ticket" parentId={ticket.id} />
          </Box>
        </Grid>

        {/* Right column: Ticket Info + Related records */}
        <Grid size={{ xs: 12, md: 4 }}>
          <TicketInfoCard ticket={ticket} statusName={currentStatus?.name} />

          {/* Asset */}
          {ticket.asset_id && (
            <Box sx={{ mt: 2 }}>
              <LinkedRecordCard
                relationship={{
                  name: 'asset',
                  type: 'one-to-many',
                  target: 'Asset',
                  foreign_key: 'id',
                }}
                parentId={ticket.asset_id}
                parentObjectType="Ticket"
              />
            </Box>
          )}

          {/* Service Contract */}
          {ticket.service_contract_id && (
            <Box sx={{ mt: 2 }}>
              <LinkedRecordCard
                relationship={{
                  name: 'service_contract',
                  type: 'one-to-many',
                  target: 'ServiceContract',
                  foreign_key: 'id',
                }}
                parentId={ticket.service_contract_id}
                parentObjectType="Ticket"
              />
            </Box>
          )}

          {/* KB Articles (M2M via TicketKnowledgeArticle) */}
          <Box sx={{ mt: 2 }}>
            <LinkedRecordCard
              relationship={{
                name: 'knowledge_articles',
                type: 'many-to-many',
                target: 'KnowledgeArticle',
                through: 'TicketKnowledgeArticle',
              }}
              parentId={ticket.id}
              parentObjectType="Ticket"
            />
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
}
