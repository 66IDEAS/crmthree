import { useState, useEffect, useCallback } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import Avatar from '@mui/material/Avatar';
import CircularProgress from '@mui/material/CircularProgress';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import Menu from '@mui/material/Menu';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import FormControlLabel from '@mui/material/FormControlLabel';
import Checkbox from '@mui/material/Checkbox';
import Snackbar from '@mui/material/Snackbar';
import DataService from '../../services/DataService';
import { useAuth } from '../../contexts/AuthContext';
import { fetchWhitelistEntries, addWhitelistEntry } from '../../services/WhitelistService';
import { t } from '../../services/TranslationService';

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Status of a profile: pending (invited, never signed in), inactive, or active. */
function statusOf(user) {
  if (!user.auth_uid) return 'pending';
  return user.active === false ? 'inactive' : 'active';
}

export default function UserManagementSection() {
  const { userProfile } = useAuth();
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [whitelist, setWhitelist] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [toast, setToast] = useState(null);
  const [savingId, setSavingId] = useState(null);
  const [menuAnchor, setMenuAnchor] = useState(null);
  const [menuUser, setMenuUser] = useState(null);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [u, r, w] = await Promise.all([
        DataService.list('UserProfile', { pageSize: 500 }),
        DataService.list('Role', { pageSize: 100 }),
        fetchWhitelistEntries().catch(() => []),
      ]);
      setUsers(u.sort((a, b) => (a.last_name || '').localeCompare(b.last_name || '')));
      setRoles(r.sort((a, b) => (a.name || '').localeCompare(b.name || '')));
      setWhitelist(w);
    } catch (err) {
      setError(err.message || t('settings.users.load_failed', 'Failed to load users'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  // resolved at render time so translations are loaded and language changes apply
  const statusChip = {
    active: { color: 'success', label: t('settings.users.status_active', 'Active') },
    inactive: { color: 'default', label: t('settings.users.status_inactive', 'Inactive') },
    pending: { color: 'warning', label: t('settings.users.status_pending', 'Pending') },
  };

  const isSelf = (u) => u.id === userProfile?.id;
  const roleName = (id) => roles.find((r) => r.id === id)?.name || '—';
  const pendingCount = users.filter((u) => statusOf(u) === 'pending').length;

  const patch = async (user, changes, message) => {
    setSavingId(user.id);
    setError(null);
    try {
      await DataService.update('UserProfile', user.id, changes);
      setUsers((prev) => prev.map((u) => (u.id === user.id ? { ...u, ...changes } : u)));
      setToast(message);
    } catch (err) {
      setError(err.message || t('settings.users.save_failed', 'Failed to save user'));
    } finally {
      setSavingId(null);
    }
  };

  const handleRoleChange = (user, roleId) =>
    patch(user, { role_id: roleId },
      t('settings.users.role_saved', 'Role updated — takes effect on their next sign-in'));

  const handleToggleActive = (user) => {
    const next = user.active === false;
    patch(user, { active: next },
      next ? t('settings.users.reactivated', 'User reactivated')
           : t('settings.users.deactivated', 'User deactivated'));
    setMenuAnchor(null);
  };

  const handleDelete = async () => {
    const user = confirmDelete;
    setConfirmDelete(null);
    setSavingId(user.id);
    try {
      await DataService.remove('UserProfile', user.id);
      setUsers((prev) => prev.filter((u) => u.id !== user.id));
      setToast(t('settings.users.deleted', 'User removed'));
    } catch (err) {
      setError(err.message || t('settings.users.delete_failed', 'Failed to delete user'));
    } finally {
      setSavingId(null);
    }
  };

  const copyInstructions = (user) => {
    const url = window.location.origin;
    navigator.clipboard?.writeText(
      t('settings.users.instructions',
        'You have access to CRMThree. Open {url} and sign in with Google using {email}.')
        .replace('{url}', url).replace('{email}', user.email)
    );
    setToast(t('settings.users.instructions_copied', 'Sign-in instructions copied to clipboard'));
    setMenuAnchor(null);
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {t('settings.users.title', 'User Management')}
          </Typography>
          <Chip size="small" label={users.length} />
          {pendingCount > 0 && (
            <Chip size="small" color="warning"
              label={t('settings.users.pending_count', '{n} pending').replace('{n}', pendingCount)} />
          )}
        </Box>
      </AccordionSummary>
      <AccordionDetails>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('settings.users.description',
            'Everyone with access to this CRM. Invite someone by email and they can sign in with Google straight away — their profile is claimed automatically on first sign-in.')}
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>
        )}

        <Box sx={{ mb: 2 }}>
          <Button variant="contained" size="small" startIcon={<PersonAddIcon />}
            onClick={() => setInviteOpen(true)}>
            {t('settings.users.invite', 'Invite User')}
          </Button>
        </Box>

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
            <CircularProgress size={24} />
          </Box>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('settings.users.col_name', 'Name')}</TableCell>
                <TableCell>{t('settings.users.col_email', 'Email')}</TableCell>
                <TableCell sx={{ minWidth: 140 }}>{t('settings.users.col_role', 'Role')}</TableCell>
                <TableCell>{t('settings.users.col_status', 'Status')}</TableCell>
                <TableCell>{t('settings.users.col_level', 'Level')}</TableCell>
                <TableCell align="right" />
              </TableRow>
            </TableHead>
            <TableBody>
              {users.map((u) => {
                const status = statusOf(u);
                const chip = statusChip[status];
                return (
                  <TableRow key={u.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Avatar src={u.avatar_url} sx={{ width: 28, height: 28, fontSize: 13 }}>
                          {(u.first_name || u.email || '?')[0]?.toUpperCase()}
                        </Avatar>
                        <Typography variant="body2">
                          {`${u.first_name || ''} ${u.last_name || ''}`.trim() || '—'}
                        </Typography>
                        {isSelf(u) && <Chip size="small" label={t('settings.users.you', 'You')} />}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">{u.email}</Typography>
                    </TableCell>
                    <TableCell>
                      <Tooltip title={isSelf(u)
                        ? t('settings.users.no_self_role', 'You cannot change your own role')
                        : ''}>
                        <span>
                          <Select size="small" fullWidth value={u.role_id || ''}
                            disabled={isSelf(u) || savingId === u.id}
                            onChange={(e) => handleRoleChange(u, e.target.value)}>
                            {roles.map((r) => (
                              <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>
                            ))}
                          </Select>
                        </span>
                      </Tooltip>
                    </TableCell>
                    <TableCell>
                      <Tooltip title={status === 'pending'
                        ? t('settings.users.pending_hint', 'Invited — has not signed in yet')
                        : ''}>
                        <Chip size="small" color={chip.color} label={chip.label} />
                      </Tooltip>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {u.level_name || '—'} · {u.xp_total || 0} XP
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <IconButton size="small"
                        onClick={(e) => { setMenuAnchor(e.currentTarget); setMenuUser(u); }}>
                        <MoreVertIcon fontSize="small" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}

        <Menu anchorEl={menuAnchor} open={Boolean(menuAnchor)} onClose={() => setMenuAnchor(null)}>
          <MenuItem onClick={() => copyInstructions(menuUser)}>
            {t('settings.users.copy_instructions', 'Copy sign-in instructions')}
          </MenuItem>
          <MenuItem disabled={menuUser ? isSelf(menuUser) : true}
            onClick={() => handleToggleActive(menuUser)}>
            {menuUser?.active === false
              ? t('settings.users.reactivate', 'Reactivate')
              : t('settings.users.deactivate', 'Deactivate')}
          </MenuItem>
          <MenuItem disabled={menuUser ? isSelf(menuUser) : true}
            onClick={() => { setConfirmDelete(menuUser); setMenuAnchor(null); }}
            sx={{ color: 'error.main' }}>
            {t('settings.users.delete', 'Delete user')}
          </MenuItem>
        </Menu>

        <InviteDialog
          open={inviteOpen}
          onClose={() => setInviteOpen(false)}
          roles={roles}
          users={users}
          whitelist={whitelist}
          currentUserId={userProfile?.id}
          onCreated={(created, addedToWhitelist) => {
            setUsers((prev) => [...prev, created]
              .sort((a, b) => (a.last_name || '').localeCompare(b.last_name || '')));
            setInviteOpen(false);
            setToast(addedToWhitelist
              ? t('settings.users.invited_whitelisted', 'User invited and added to the access whitelist')
              : t('settings.users.invited', 'User invited — they can sign in with Google now'));
            if (addedToWhitelist) fetchWhitelistEntries().then(setWhitelist).catch(() => {});
          }}
        />

        <Dialog open={Boolean(confirmDelete)} onClose={() => setConfirmDelete(null)}>
          <DialogTitle>{t('settings.users.delete_title', 'Delete user?')}</DialogTitle>
          <DialogContent>
            <Typography variant="body2">
              {t('settings.users.delete_body',
                'Remove {name} from this CRM. Records they created or own are not affected, and their Google account is untouched — they will see the "not provisioned" screen if they sign in again.')
                .replace('{name}', `${confirmDelete?.first_name || ''} ${confirmDelete?.last_name || ''}`.trim() || confirmDelete?.email || '')}
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setConfirmDelete(null)}>{t('ui.cancel', 'Cancel')}</Button>
            <Button color="error" variant="contained" onClick={handleDelete}>
              {t('settings.users.delete', 'Delete user')}
            </Button>
          </DialogActions>
        </Dialog>

        <Snackbar open={Boolean(toast)} autoHideDuration={4000}
          onClose={() => setToast(null)} message={toast} />
      </AccordionDetails>
    </Accordion>
  );
}

function InviteDialog({ open, onClose, roles, users, whitelist, currentUserId, onCreated }) {
  const [email, setEmail] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [roleId, setRoleId] = useState('');
  const [addWhitelist, setAddWhitelist] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!open) return;
    setEmail(''); setFirstName(''); setLastName(''); setError(null); setAddWhitelist(true);
    setRoleId(roles.find((r) => r.name === 'User')?.id || roles[0]?.id || '');
  }, [open, roles]);

  const normalized = email.trim().toLowerCase();
  const duplicate = users.some((u) => (u.email || '').toLowerCase() === normalized);
  const emailValid = EMAIL_RE.test(normalized);
  // whitelist is only restrictive once it has at least one entry
  const blockedByWhitelist =
    whitelist.length > 0 && emailValid &&
    !whitelist.some((w) => w.type === 'email'
      ? w.value === normalized
      : normalized.endsWith('@' + w.value));

  const submit = async () => {
    setSaving(true); setError(null);
    try {
      const profile = await DataService.create('UserProfile', {
        auth_uid: '',
        email: normalized,
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        role_id: roleId,
        avatar_url: '',
        xp_total: 0,
        level: 1,
        level_name: 'Rookie',
        current_streak_days: 0,
        longest_streak_days: 0,
        active: true,
        theme_preference: 'System',
        language_preference: 'en',
      });
      let whitelisted = false;
      if (blockedByWhitelist && addWhitelist) {
        await addWhitelistEntry('email', normalized, currentUserId);
        whitelisted = true;
      }
      onCreated(profile, whitelisted);
    } catch (err) {
      setError(err.message || t('settings.users.invite_failed', 'Failed to invite user'));
    } finally {
      setSaving(false);
    }
  };

  const canSubmit = emailValid && !duplicate && firstName.trim() && lastName.trim() && roleId && !saving;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{t('settings.users.invite_title', 'Invite User')}</DialogTitle>
      <DialogContent>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('settings.users.invite_help',
            'Creates their profile now. The next time they sign in with Google using this address, it is linked to their account automatically.')}
        </Typography>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField label={t('settings.users.col_email', 'Email')} value={email} required
            onChange={(e) => setEmail(e.target.value)} size="small" fullWidth autoFocus
            error={Boolean(email) && (!emailValid || duplicate)}
            helperText={
              duplicate ? t('settings.users.duplicate', 'A profile with this email already exists')
                : email && !emailValid ? t('settings.users.invalid_email', 'Enter a valid email address')
                : ''
            } />
          <Box sx={{ display: 'flex', gap: 2 }}>
            <TextField label={t('settings.users.first_name', 'First Name')} value={firstName} required
              onChange={(e) => setFirstName(e.target.value)} size="small" fullWidth />
            <TextField label={t('settings.users.last_name', 'Last Name')} value={lastName} required
              onChange={(e) => setLastName(e.target.value)} size="small" fullWidth />
          </Box>
          <Select size="small" value={roleId} onChange={(e) => setRoleId(e.target.value)} fullWidth>
            {roles.map((r) => <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>)}
          </Select>
          {blockedByWhitelist && (
            <Alert severity="warning">
              {t('settings.users.whitelist_warning',
                'This address is not on the access whitelist and would be rejected at sign-in.')}
              <FormControlLabel sx={{ display: 'block', mt: 1 }}
                control={<Checkbox checked={addWhitelist} size="small"
                  onChange={(e) => setAddWhitelist(e.target.checked)} />}
                label={t('settings.users.add_to_whitelist', 'Add to whitelist')} />
            </Alert>
          )}
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{t('ui.cancel', 'Cancel')}</Button>
        <Button variant="contained" disabled={!canSubmit} onClick={submit}>
          {saving ? <CircularProgress size={20} /> : t('settings.users.invite', 'Invite User')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
