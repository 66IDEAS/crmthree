import { useNavigate } from 'react-router';
import Popover from '@mui/material/Popover';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Divider from '@mui/material/Divider';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import IconButton from '@mui/material/IconButton';
import CloseIcon from '@mui/icons-material/Close';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import { useNotifications } from '../../contexts/NotificationContext';
import { resolveSlug } from '../../config/navigation';
import { t } from '../../services/TranslationService';

function timeAgo(dateString) {
  if (!dateString) return '';
  const seconds = Math.floor((Date.now() - new Date(dateString).getTime()) / 1000);
  if (seconds < 60) return 'just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
  return new Date(dateString).toLocaleDateString();
}

/**
 * UX18: Notification Panel — Popover showing recent notifications.
 */
export default function NotificationPanel({ anchorEl, open, onClose }) {
  const navigate = useNavigate();
  const { notifications, unreadCount, markAsRead, markAllAsRead, deleteNotification } =
    useNotifications();

  const handleClick = async (notification) => {
    await markAsRead(notification.id);
    if (notification.link_type && notification.link_id) {
      const slug = resolveSlug(notification.link_type);
      if (slug) {
        navigate(`/${slug}/${notification.link_id}`);
      }
    }
    onClose();
  };

  const handleDelete = async (e, id) => {
    e.stopPropagation();
    await deleteNotification(id);
  };

  return (
    <Popover
      open={open}
      anchorEl={anchorEl}
      onClose={onClose}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      slotProps={{ paper: { sx: { width: 380, maxHeight: 500 } } }}
    >
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', px: 2, py: 1.5 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('menu.notifications', 'Notifications')}
        </Typography>
        <Button
          size="small"
          onClick={markAllAsRead}
          disabled={unreadCount === 0}
          sx={{ textTransform: 'none' }}
        >
          {t('menu.mark_all_read', 'Mark all as read')}
        </Button>
      </Box>
      <Divider />

      {/* Notification list */}
      {notifications.length === 0 ? (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 5, color: 'text.secondary' }}>
          <NotificationsNoneIcon sx={{ fontSize: 48, mb: 1 }} />
          <Typography variant="body2">{t('menu.no_notifications', 'No notifications')}</Typography>
        </Box>
      ) : (
        <List sx={{ maxHeight: 400, overflowY: 'auto', py: 0 }}>
          {notifications.map((n) => (
            <ListItemButton
              key={n.id}
              onClick={() => handleClick(n)}
              sx={{
                alignItems: 'flex-start',
                bgcolor: n.read ? 'transparent' : 'action.hover',
                '&:hover': { bgcolor: 'action.selected' },
              }}
            >
              {/* Unread indicator */}
              <Box
                sx={{
                  width: 8,
                  height: 8,
                  borderRadius: '50%',
                  bgcolor: n.read ? 'transparent' : 'primary.main',
                  mt: 1.5,
                  mr: 1.5,
                  flexShrink: 0,
                }}
              />
              <ListItemText
                primary={
                  <Typography
                    variant="body2"
                    sx={{ fontWeight: n.read ? 400 : 600 }}
                    noWrap
                  >
                    {n.title}
                  </Typography>
                }
                secondary={
                  <Box component="span">
                    {n.message && (
                      <Typography variant="caption" display="block" noWrap color="text.secondary">
                        {n.message}
                      </Typography>
                    )}
                    <Typography variant="caption" color="text.disabled">
                      {timeAgo(n.created_at)}
                    </Typography>
                  </Box>
                }
              />
              <IconButton
                size="small"
                onClick={(e) => handleDelete(e, n.id)}
                sx={{ mt: 0.5, ml: 0.5 }}
              >
                <CloseIcon fontSize="small" />
              </IconButton>
            </ListItemButton>
          ))}
        </List>
      )}
    </Popover>
  );
}
