import { useState, useEffect, useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Alert from '@mui/material/Alert';
import Paper from '@mui/material/Paper';
import Grid from '@mui/material/Grid';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import EditIcon from '@mui/icons-material/Edit';
import LockIcon from '@mui/icons-material/Lock';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import { useParams, useNavigate } from 'react-router';
import { useUI } from '../contexts/UIContext';
import { useNavigationHistory } from '../contexts/NavigationHistoryContext';
import { useRecord, useList, useMutation } from '../hooks/useDataService';
import ModelRegistry from '../model/ModelRegistry';
import { getDisplayName, getAutoNumberField, formatAutoNumber } from '../utils/fieldUtils';
import ObjectCreatePage from './ObjectCreatePage';
import LoadingSpinner from '../components/common/LoadingSpinner';
import AiRecordSummary from '../components/records/AiRecordSummary';
import LinkedRecordCard from '../components/records/LinkedRecordCard';
import FieldRenderer from '../components/fields/FieldRenderer';
import DealStageProgress from '../components/dealroom/DealStageProgress';
import ActivityTimeline from '../components/dealroom/ActivityTimeline';
import CommentThread from '../components/dealroom/CommentThread';
import DealRoomQuickActions from '../components/dealroom/DealRoomQuickActions';
import { t } from '../services/TranslationService';

const STATUS_COLORS = {
  Active: 'success',
  Closed: 'default',
};

function DealInfoCard({ opportunity, stages }) {
  if (!opportunity) return null;

  const fields = ModelRegistry.getSpecificFields('Opportunity');
  const currentStage = stages?.find((s) => s.id === opportunity.stage_id);

  const metrics = [
    { name: 'amount', label: t('field.Opportunity.amount', 'Amount') },
    { name: 'probability', label: t('field.Opportunity.probability', 'Probability') },
    { name: 'expected_close_date', label: t('field.Opportunity.expected_close_date', 'Expected Close') },
    { name: 'result', label: t('field.Opportunity.result', 'Result') },
  ];

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>
        {t('section.deal_info', 'Deal Info')}
      </Typography>

      {currentStage && (
        <Box sx={{ mb: 1.5 }}>
          <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 0.25 }}>
            {t('field.Opportunity.stage_id', 'Stage')}
          </Typography>
          <Typography variant="body2">{currentStage.name}</Typography>
        </Box>
      )}

      {metrics.map(({ name, label }) => {
        const field = fields.find((f) => f.name === name);
        const value = opportunity[name];
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

      {/* Account and Owner references */}
      {['account_id', 'owner_id'].map((refName) => {
        const field = fields.find((f) => f.name === refName);
        const value = opportunity[refName];
        if (!field || !value) return null;
        return (
          <Box key={refName} sx={{ mb: 1.5 }}>
            <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 0.25 }}>
              {t(`field.Opportunity.${refName}`, field.description || refName)}
            </Typography>
            <FieldRenderer field={field} value={value} />
          </Box>
        );
      })}
    </Paper>
  );
}

export default function DealRoomPage() {
  const { id } = useParams();

  // When id is "new", render the generic create form for DealRoom
  if (id === 'new') return <ObjectCreatePage overrideObjectType="DealRoom" />;

  return <DealRoomDetailView id={id} />;
}

function DealRoomDetailView({ id }) {
  const navigate = useNavigate();
  const { isMobile } = useUI();
  const { updateCurrentLabel } = useNavigationHistory();

  // Load Deal Room record
  const { data: dealRoom, loading: drLoading, error: drError, refetch: refetchDR } = useRecord('DealRoom', id);

  // Load linked Opportunity (only when dealRoom is loaded)
  const { data: opportunity, loading: oppLoading, refetch: refetchOpp } = useRecord(
    'Opportunity',
    dealRoom?.opportunity_id
  );

  // Load pipeline stages
  const stageOpts = useMemo(() => ({ pageSize: 100 }), []);
  const { data: stages } = useList('PipelineStage', stageOpts);
  const sortedStages = useMemo(
    () => [...(stages || [])].filter((s) => s.active !== false).sort((a, b) => a.sort_order - b.sort_order),
    [stages]
  );

  // Deal Room fields for display
  const drFields = ModelRegistry.getSpecificFields('DealRoom');
  const autoNumberField = getAutoNumberField(drFields);
  const displayName = dealRoom?.name || '';

  // Update breadcrumb
  useEffect(() => {
    if (displayName) updateCurrentLabel(displayName);
  }, [displayName, updateCurrentLabel]);

  // Edit and Close Deal Room handlers
  const { update: updateDR } = useMutation('DealRoom');
  const [editOpen, setEditOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [editDesc, setEditDesc] = useState('');
  const [closing, setClosing] = useState(false);

  const openEdit = () => {
    setEditName(dealRoom?.name || '');
    setEditDesc(dealRoom?.description || '');
    setEditOpen(true);
  };
  const handleEditSave = async () => {
    if (!editName.trim()) return;
    await updateDR(id, { name: editName.trim(), description: editDesc.trim() });
    setEditOpen(false);
    refetchDR();
  };

  const handleClose = async () => {
    setClosing(true);
    await updateDR(id, { status: 'Closed' });
    refetchDR();
    setClosing(false);
  };

  const handleRefetch = () => {
    refetchDR();
    refetchOpp();
  };

  // Loading states
  if (drLoading || (dealRoom && oppLoading)) return <LoadingSpinner />;

  if (drError) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="error">{drError.message || t('ui.failed_to_load_record', 'Failed to load record.')}</Alert>
      </Box>
    );
  }

  if (!dealRoom) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{t('dealroom.not_found', 'Deal Room not found.')}</Alert>
      </Box>
    );
  }

  const isClosed = dealRoom.status === 'Closed';

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
        {autoNumberField && dealRoom[autoNumberField.name] && (
          <Chip
            label={formatAutoNumber(dealRoom[autoNumberField.name])}
            size="small"
            variant="outlined"
          />
        )}
        <Chip
          label={dealRoom.status}
          size="small"
          color={STATUS_COLORS[dealRoom.status] || 'default'}
        />
        {!isClosed && (
          <Tooltip title={t('ui.edit', 'Edit')}>
            <IconButton size="small" onClick={openEdit}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        )}
        <Box sx={{ flex: 1 }} />
        {!isClosed && (
          <Button
            variant="outlined"
            size="small"
            startIcon={<LockIcon />}
            onClick={handleClose}
            disabled={closing}
            color="warning"
          >
            {t('action.close_deal_room', 'Close Deal Room')}
          </Button>
        )}
        <Button
          variant="outlined"
          size="small"
          startIcon={<OpenInNewIcon />}
          onClick={() => navigate(`/opportunities/${dealRoom.opportunity_id}`)}
        >
          {t('action.view_opportunity', 'View Opportunity')}
        </Button>
      </Box>

      {/* AI Summary (reuse existing for Opportunity) */}
      {opportunity && (
        <Box sx={{ px: 2, mb: 1 }}>
          <AiRecordSummary objectType="Opportunity" record={opportunity} />
        </Box>
      )}

      {/* Quick Actions */}
      {opportunity && !isClosed && (
        <DealRoomQuickActions
          opportunity={opportunity}
          stages={sortedStages}
          dealRoomId={id}
          onRefetch={handleRefetch}
        />
      )}

      {/* Pipeline Stepper */}
      {opportunity && (
        <DealStageProgress
          stages={sortedStages}
          currentStageId={opportunity.stage_id}
          result={opportunity.result}
        />
      )}

      {/* Two-column layout */}
      <Grid container spacing={2} sx={{ px: 2, pb: 3 }}>
        {/* Left column: Timeline + Comments */}
        <Grid size={{ xs: 12, md: 8 }}>
          {opportunity && (
            <ActivityTimeline opportunityId={opportunity.id} />
          )}
          <Box sx={{ mt: 2 }}>
            <CommentThread parentType="DealRoom" parentId={id} />
          </Box>
        </Grid>

        {/* Right column: Deal Info + Contacts + Documents */}
        <Grid size={{ xs: 12, md: 4 }}>
          {opportunity && (
            <DealInfoCard opportunity={opportunity} stages={sortedStages} />
          )}

          {/* Contacts with roles (M2M via OpportunityContact on the Opportunity) */}
          {opportunity && (
            <Box sx={{ mt: 2 }}>
              <LinkedRecordCard
                relationship={{
                  name: 'contacts',
                  type: 'many-to-many',
                  target: 'Contact',
                  through: 'OpportunityContact',
                }}
                parentId={opportunity.id}
                parentObjectType="Opportunity"
              />
            </Box>
          )}

          {/* Documents linked to the Deal Room */}
          <Box sx={{ mt: 2 }}>
            <LinkedRecordCard
              relationship={{
                name: 'documents',
                type: 'one-to-many',
                target: 'Document',
                foreign_key: 'parent_id',
                condition: "parent_type = 'DealRoom'",
              }}
              parentId={id}
              parentObjectType="DealRoom"
            />
          </Box>
        </Grid>
      </Grid>

      {/* Edit Deal Room Dialog */}
      <Dialog open={editOpen} onClose={() => setEditOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>{t('action.edit_deal_room', 'Edit Deal Room')}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            label={t('field.DealRoom.name', 'Name')}
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
            fullWidth
            required
            sx={{ mt: 1, mb: 2 }}
          />
          <TextField
            label={t('field.DealRoom.description', 'Description')}
            value={editDesc}
            onChange={(e) => setEditDesc(e.target.value)}
            fullWidth
            multiline
            minRows={3}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditOpen(false)}>{t('ui.cancel', 'Cancel')}</Button>
          <Button variant="contained" onClick={handleEditSave} disabled={!editName.trim()}>
            {t('ui.save', 'Save')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
