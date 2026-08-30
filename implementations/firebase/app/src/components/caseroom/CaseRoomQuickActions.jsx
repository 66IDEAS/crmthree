import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import Autocomplete from '@mui/material/Autocomplete';
import ListItemIcon from '@mui/material/ListItemIcon';
import CheckIcon from '@mui/icons-material/Check';
import UpdateIcon from '@mui/icons-material/Update';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import LinkIcon from '@mui/icons-material/Link';
import { useMutation, useList } from '../../hooks/useDataService';
import { useAuth } from '../../contexts/AuthContext';
import { t } from '../../services/TranslationService';

export default function CaseRoomQuickActions({ ticket, ticketStatuses, onRefetch }) {
  const { userProfile } = useAuth();
  const { update: updateTicket } = useMutation('Ticket');
  const { create: createComment } = useMutation('Comment');
  const { create: createJunction } = useMutation('TicketKnowledgeArticle');

  const [statusAnchor, setStatusAnchor] = useState(null);
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteText, setNoteText] = useState('');
  const [linkOpen, setLinkOpen] = useState(false);
  const [selectedArticle, setSelectedArticle] = useState(null);

  // Load KB articles for linking
  const kbOpts = useMemo(() => ({ pageSize: 200 }), []);
  const { data: kbArticles } = useList(linkOpen ? 'KnowledgeArticle' : null, linkOpen ? kbOpts : {});

  const handleStatusChange = async (status) => {
    setStatusAnchor(null);
    const updates = { status_id: status.id };
    const now = new Date().toISOString();

    // Auto-set timestamps based on status name
    const statusName = (status.name || '').toLowerCase();
    if (statusName.includes('progress') || statusName.includes('working')) {
      if (!ticket.first_response_at) updates.first_response_at = now;
    }
    if (statusName.includes('resolved') || statusName.includes('fixed')) {
      updates.resolved_at = now;
      if (!ticket.first_response_at) updates.first_response_at = now;
    }
    if (statusName.includes('closed')) {
      updates.closed_at = now;
      if (!ticket.resolved_at) updates.resolved_at = now;
      if (!ticket.first_response_at) updates.first_response_at = now;
    }

    await updateTicket(ticket.id, updates);
    onRefetch();
  };

  const handleAddNote = async () => {
    if (!noteText.trim()) return;
    await createComment({
      parent_type: 'Ticket',
      parent_id: ticket.id,
      content: noteText.trim(),
      author_id: userProfile?.id,
    });
    setNoteText('');
    setNoteOpen(false);
    onRefetch();
  };

  const handleLinkArticle = async () => {
    if (!selectedArticle) return;
    await createJunction({
      ticket_id: ticket.id,
      knowledge_article_id: selectedArticle.id,
    });
    setSelectedArticle(null);
    setLinkOpen(false);
    onRefetch();
  };

  return (
    <>
      <Box sx={{ display: 'flex', gap: 1, mx: 2, mb: 2, flexWrap: 'wrap' }}>
        <Button
          variant="outlined"
          size="small"
          startIcon={<UpdateIcon />}
          onClick={(e) => setStatusAnchor(e.currentTarget)}
        >
          {t('action.update_status', 'Update Status')}
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
          startIcon={<LinkIcon />}
          onClick={() => setLinkOpen(true)}
        >
          {t('action.link_kb_article', 'Link KB Article')}
        </Button>
      </Box>

      {/* Status selector menu */}
      <Menu
        anchorEl={statusAnchor}
        open={Boolean(statusAnchor)}
        onClose={() => setStatusAnchor(null)}
      >
        {(ticketStatuses || []).map((status) => (
          <MenuItem
            key={status.id}
            selected={status.id === ticket.status_id}
            onClick={() => handleStatusChange(status)}
          >
            {status.id === ticket.status_id && (
              <ListItemIcon>
                <CheckIcon fontSize="small" />
              </ListItemIcon>
            )}
            {status.name}
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
            placeholder={t('caseroom.note_placeholder', 'Write your note...')}
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

      {/* Link KB Article dialog */}
      <Dialog open={linkOpen} onClose={() => setLinkOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('action.link_kb_article', 'Link KB Article')}</DialogTitle>
        <DialogContent>
          <Autocomplete
            options={kbArticles || []}
            getOptionLabel={(opt) => opt.title || opt.name || opt.id}
            value={selectedArticle}
            onChange={(_, v) => setSelectedArticle(v)}
            renderInput={(params) => (
              <TextField
                {...params}
                label={t('field.KnowledgeArticle.title', 'Knowledge Article')}
                sx={{ mt: 1 }}
              />
            )}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLinkOpen(false)}>{t('ui.cancel', 'Cancel')}</Button>
          <Button variant="contained" onClick={handleLinkArticle} disabled={!selectedArticle}>
            {t('action.link', 'Link')}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
