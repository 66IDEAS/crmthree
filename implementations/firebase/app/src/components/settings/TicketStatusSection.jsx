import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Checkbox from '@mui/material/Checkbox';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import AddIcon from '@mui/icons-material/Add';
import Chip from '@mui/material/Chip';
import DataService from '../../services/DataService';
import { t } from '../../services/TranslationService';

const EMPTY_STATUS = {
  name: '',
  sort_order: 0,
  is_resolved: false,
  is_closed: false,
  active: true,
  description: '',
};

/**
 * UX37: Ticket Status Configuration in Settings (Admin Only).
 * Allows admins to manage the configurable TicketStatus lookup table.
 */
export default function TicketStatusSection() {
  const [statuses, setStatuses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [editId, setEditId] = useState(null);
  const [editValues, setEditValues] = useState({});
  const [adding, setAdding] = useState(false);
  const [newValues, setNewValues] = useState({ ...EMPTY_STATUS });

  useEffect(() => {
    loadStatuses();
  }, []);

  const loadStatuses = async () => {
    setLoading(true);
    try {
      const data = await DataService.list('TicketStatus', {
        sort: { field: 'sort_order', direction: 'asc' },
        pageSize: 100,
      });
      setStatuses(data);
    } catch (err) {
      setError(err.message || t('settings.ticket.load_failed', 'Failed to load ticket statuses'));
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = async () => {
    if (!newValues.name.trim()) {
      setError(t('settings.ticket.name_required', 'Status name is required.'));
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await DataService.create('TicketStatus', {
        ...newValues,
        name: newValues.name.trim(),
        sort_order: Number(newValues.sort_order) || 0,
      });
      setAdding(false);
      setNewValues({ ...EMPTY_STATUS });
      await loadStatuses();
    } catch (err) {
      setError(err.message || t('settings.ticket.create_failed', 'Failed to create status'));
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (status) => {
    setEditId(status.id);
    setEditValues({
      name: status.name,
      sort_order: status.sort_order,
      is_resolved: status.is_resolved,
      is_closed: status.is_closed,
      active: status.active,
      description: status.description || '',
    });
  };

  const handleSave = async () => {
    if (!editValues.name.trim()) {
      setError(t('settings.ticket.name_required', 'Status name is required.'));
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await DataService.update('TicketStatus', editId, {
        ...editValues,
        name: editValues.name.trim(),
        sort_order: Number(editValues.sort_order) || 0,
      });
      setEditId(null);
      setEditValues({});
      await loadStatuses();
    } catch (err) {
      setError(err.message || t('settings.ticket.update_failed', 'Failed to update status'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    setSaving(true);
    setError(null);
    try {
      await DataService.remove('TicketStatus', id);
      setStatuses((prev) => prev.filter((s) => s.id !== id));
    } catch (err) {
      setError(err.message || t('settings.ticket.delete_failed', 'Failed to delete status'));
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    setEditId(null);
    setEditValues({});
  };

  const renderRow = (values, onChange, onSave, onCancel, isNew) => (
    <TableRow>
      <TableCell>
        <TextField
          size="small"
          value={values.name}
          onChange={(e) => onChange({ ...values, name: e.target.value })}
          placeholder="Status name"
          sx={{ minWidth: 120 }}
          disabled={saving}
        />
      </TableCell>
      <TableCell>
        <TextField
          size="small"
          type="number"
          value={values.sort_order}
          onChange={(e) => onChange({ ...values, sort_order: e.target.value })}
          sx={{ width: 80 }}
          disabled={saving}
        />
      </TableCell>
      <TableCell align="center">
        <Checkbox
          checked={values.is_resolved}
          onChange={(e) => onChange({ ...values, is_resolved: e.target.checked })}
          disabled={saving}
          size="small"
        />
      </TableCell>
      <TableCell align="center">
        <Checkbox
          checked={values.is_closed}
          onChange={(e) => onChange({ ...values, is_closed: e.target.checked })}
          disabled={saving}
          size="small"
        />
      </TableCell>
      <TableCell align="center">
        <Checkbox
          checked={values.active}
          onChange={(e) => onChange({ ...values, active: e.target.checked })}
          disabled={saving}
          size="small"
        />
      </TableCell>
      <TableCell>
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <IconButton size="small" onClick={onSave} disabled={saving} color="primary">
            <SaveIcon fontSize="small" />
          </IconButton>
          <IconButton size="small" onClick={onCancel} disabled={saving}>
            <CancelIcon fontSize="small" />
          </IconButton>
        </Box>
      </TableCell>
    </TableRow>
  );

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.ticket.title', 'Ticket Statuses')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
        <Typography variant="body2" color="text.secondary">
          {t('settings.ticket.description', 'Configure the available statuses for service tickets. These appear in the "Current Ticket Status" dropdown.')}
        </Typography>
        {!adding && (
          <Button
            size="small"
            startIcon={<AddIcon />}
            onClick={() => setAdding(true)}
            disabled={saving}
          >
            {t('settings.ticket.add', 'Add Status')}
          </Button>
        )}
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
          <CircularProgress size={24} />
        </Box>
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ticket.name', 'Name')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ticket.order', 'Order')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="center">{t('settings.ticket.resolved', 'Resolved')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="center">{t('settings.ticket.closed', 'Closed')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="center">{t('ui.active', 'Active')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ticket.actions', 'Actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {statuses.map((status) =>
                editId === status.id ? (
                  renderRow(
                    editValues,
                    setEditValues,
                    handleSave,
                    handleCancel,
                    false
                  )
                ) : (
                  <TableRow key={status.id}>
                    <TableCell>
                      {status.name}
                      {!status.active && (
                        <Chip label={t('ui.inactive', 'Inactive')} size="small" sx={{ ml: 1 }} color="default" />
                      )}
                    </TableCell>
                    <TableCell>{status.sort_order}</TableCell>
                    <TableCell align="center">
                      {status.is_resolved ? 'Yes' : ''}
                    </TableCell>
                    <TableCell align="center">
                      {status.is_closed ? 'Yes' : ''}
                    </TableCell>
                    <TableCell align="center">
                      {status.active ? 'Yes' : 'No'}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 0.5 }}>
                        <IconButton
                          size="small"
                          onClick={() => handleEdit(status)}
                          disabled={saving}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleDelete(status.id)}
                          disabled={saving}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </TableCell>
                  </TableRow>
                )
              )}
              {adding &&
                renderRow(
                  newValues,
                  setNewValues,
                  handleAdd,
                  () => {
                    setAdding(false);
                    setNewValues({ ...EMPTY_STATUS });
                  },
                  true
                )}
              {statuses.length === 0 && !adding && (
                <TableRow>
                  <TableCell colSpan={6}>
                    <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic', py: 1 }}>
                      {t('settings.ticket.empty', 'No ticket statuses configured. Click "Add Status" to create one.')}
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </AccordionDetails>
    </Accordion>
  );
}
