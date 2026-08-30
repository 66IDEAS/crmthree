import { useState } from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import ListItemIcon from '@mui/material/ListItemIcon';
import CheckIcon from '@mui/icons-material/Check';
import StairsIcon from '@mui/icons-material/Stairs';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import EventIcon from '@mui/icons-material/Event';
import { useNavigate } from 'react-router';
import { useMutation } from '../../hooks/useDataService';
import { useAuth } from '../../contexts/AuthContext';
import { t } from '../../services/TranslationService';

export default function DealRoomQuickActions({ opportunity, stages, dealRoomId, onRefetch }) {
  const navigate = useNavigate();
  const { userProfile } = useAuth();
  const { update: updateOpp } = useMutation('Opportunity');
  const { create: createComment } = useMutation('Comment');

  const [stageAnchor, setStageAnchor] = useState(null);
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteText, setNoteText] = useState('');

  const handleStageChange = async (stage) => {
    setStageAnchor(null);
    await updateOpp(opportunity.id, {
      stage_id: stage.id,
      probability: stage.default_probability ?? opportunity.probability,
    });
    onRefetch();
  };

  const handleAddNote = async () => {
    if (!noteText.trim()) return;
    await createComment({
      parent_type: 'DealRoom',
      parent_id: dealRoomId,
      content: noteText.trim(),
      author_id: userProfile?.id,
    });
    setNoteText('');
    setNoteOpen(false);
    onRefetch();
  };

  const handleScheduleFollowup = () => {
    const params = new URLSearchParams({
      type: 'Meeting',
      status: 'Planned',
      opportunity_id: opportunity.id,
      _returnTo: `/deal-rooms/${dealRoomId}`,
    });
    if (opportunity.account_id) params.set('account_id', opportunity.account_id);
    navigate(`/activities/new?${params.toString()}`);
  };

  return (
    <>
      <Box sx={{ display: 'flex', gap: 1, mx: 2, mb: 2, flexWrap: 'wrap' }}>
        <Button
          variant="outlined"
          size="small"
          startIcon={<StairsIcon />}
          onClick={(e) => setStageAnchor(e.currentTarget)}
        >
          {t('action.update_stage', 'Update Stage')}
        </Button>
        <Button
          variant="outlined"
          size="small"
          startIcon={<NoteAddIcon />}
          onClick={() => setNoteOpen(true)}
        >
          {t('action.add_note', 'Add Note')}
        </Button>
        <Button
          variant="outlined"
          size="small"
          startIcon={<EventIcon />}
          onClick={handleScheduleFollowup}
        >
          {t('action.schedule_followup', 'Schedule Follow-up')}
        </Button>
      </Box>

      {/* Stage selector menu */}
      <Menu
        anchorEl={stageAnchor}
        open={Boolean(stageAnchor)}
        onClose={() => setStageAnchor(null)}
      >
        {(stages || []).map((stage) => (
          <MenuItem
            key={stage.id}
            selected={stage.id === opportunity.stage_id}
            onClick={() => handleStageChange(stage)}
          >
            {stage.id === opportunity.stage_id && (
              <ListItemIcon>
                <CheckIcon fontSize="small" />
              </ListItemIcon>
            )}
            {stage.name}
          </MenuItem>
        ))}
      </Menu>

      {/* Add Note dialog */}
      <Dialog open={noteOpen} onClose={() => setNoteOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('action.add_note', 'Add Note')}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            multiline
            minRows={3}
            maxRows={8}
            placeholder={t('dealroom.note_placeholder', 'Write your note...')}
            value={noteText}
            onChange={(e) => setNoteText(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNoteOpen(false)}>{t('ui.cancel', 'Cancel')}</Button>
          <Button variant="contained" onClick={handleAddNote} disabled={!noteText.trim()}>
            {t('ui.save', 'Save')}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
