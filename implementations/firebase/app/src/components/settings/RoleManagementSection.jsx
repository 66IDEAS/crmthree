import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import FormControlLabel from '@mui/material/FormControlLabel';
import Checkbox from '@mui/material/Checkbox';
import Divider from '@mui/material/Divider';
import Paper from '@mui/material/Paper';
import DataService from '../../services/DataService';
import navigationItems from '../../config/navigation';
import { t } from '../../services/TranslationService';

export default function RoleManagementSection() {
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [expandedRole, setExpandedRole] = useState(null);
  const [editedItems, setEditedItems] = useState({});
  const [saving, setSaving] = useState(null);

  useEffect(() => {
    loadRoles();
  }, []);

  const loadRoles = async () => {
    setLoading(true);
    try {
      const data = await DataService.list('Role', { pageSize: 100 });
      setRoles(data.sort((a, b) => (a.name || '').localeCompare(b.name || '')));
    } catch (err) {
      setError(err.message || t('settings.roles.load_failed', 'Failed to load roles'));
    } finally {
      setLoading(false);
    }
  };

  const handleExpand = (roleId) => {
    if (expandedRole === roleId) {
      setExpandedRole(null);
      return;
    }
    setExpandedRole(roleId);
    const role = roles.find((r) => r.id === roleId);
    if (role && !editedItems[roleId]) {
      setEditedItems((prev) => ({ ...prev, [roleId]: [...(role.ribbon_items || [])] }));
    }
  };

  const handleToggleItem = (roleId, objectType) => {
    setEditedItems((prev) => {
      const current = prev[roleId] || [];
      const next = current.includes(objectType)
        ? current.filter((t) => t !== objectType)
        : [...current, objectType];
      return { ...prev, [roleId]: next };
    });
  };

  const handleSave = async (roleId) => {
    setSaving(roleId);
    setError(null);
    try {
      const items = editedItems[roleId] || [];
      await DataService.update('Role', roleId, { ribbon_items: items });
      setRoles((prev) =>
        prev.map((r) => (r.id === roleId ? { ...r, ribbon_items: items } : r))
      );
    } catch (err) {
      setError(err.message || t('settings.roles.save_failed', 'Failed to save role'));
    } finally {
      setSaving(null);
    }
  };

  const hasChanges = (roleId) => {
    const role = roles.find((r) => r.id === roleId);
    if (!role || !editedItems[roleId]) return false;
    const original = role.ribbon_items || [];
    const edited = editedItems[roleId];
    if (original.length !== edited.length) return true;
    return !original.every((item) => edited.includes(item));
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.roles.title', 'Role Management')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('settings.roles.description', 'Configure which navigation items are visible in the ribbon for each role.')}
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
            <CircularProgress size={24} />
          </Box>
        ) : roles.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
            {t('settings.roles.empty', 'No roles configured.')}
          </Typography>
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            {roles.map((role) => {
              const isExpanded = expandedRole === role.id;
              const items = editedItems[role.id] || role.ribbon_items || [];

              return (
                <Paper key={role.id} variant="outlined">
                  <Box
                    onClick={() => handleExpand(role.id)}
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 1,
                      p: 1.5,
                      cursor: 'pointer',
                      '&:hover': { bgcolor: 'action.hover' },
                    }}
                  >
                    <Box sx={{ flex: 1 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {role.name}
                      </Typography>
                      {role.description && (
                        <Typography variant="caption" color="text.secondary">
                          {role.description}
                        </Typography>
                      )}
                    </Box>
                    {role.is_system_role && (
                      <Chip label={t('settings.roles.system', 'System')} size="small" color="info" />
                    )}
                    <Chip
                      label={`${(role.ribbon_items || []).length} ${t('settings.roles.items', 'items')}`}
                      size="small"
                      variant="outlined"
                    />
                  </Box>

                  {isExpanded && (
                    <>
                      <Divider />
                      <Box sx={{ p: 2 }}>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
                          {t('settings.roles.select_items', 'Select which navigation items this role can see:')}
                        </Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0 }}>
                          {navigationItems.map((nav) => (
                            <FormControlLabel
                              key={nav.objectType}
                              control={
                                <Checkbox
                                  size="small"
                                  checked={items.includes(nav.objectType)}
                                  onChange={() => handleToggleItem(role.id, nav.objectType)}
                                />
                              }
                              label={nav.label}
                              sx={{ width: { xs: '100%', sm: '50%', md: '33%' }, m: 0 }}
                            />
                          ))}
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 1.5 }}>
                          <Button
                            variant="contained"
                            size="small"
                            onClick={() => handleSave(role.id)}
                            disabled={saving === role.id || !hasChanges(role.id)}
                          >
                            {saving === role.id
                              ? t('ui.saving', 'Saving...')
                              : t('ui.save', 'Save')}
                          </Button>
                        </Box>
                      </Box>
                    </>
                  )}
                </Paper>
              );
            })}
          </Box>
        )}
      </AccordionDetails>
    </Accordion>
  );
}
