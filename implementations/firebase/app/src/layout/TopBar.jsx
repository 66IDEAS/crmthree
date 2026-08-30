import { useState } from 'react';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import Avatar from '@mui/material/Avatar';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import Divider from '@mui/material/Divider';
import Badge from '@mui/material/Badge';
import MenuIcon from '@mui/icons-material/Menu';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import PersonIcon from '@mui/icons-material/Person';
import TimelineIcon from '@mui/icons-material/Timeline';
import LogoutIcon from '@mui/icons-material/Logout';
import { useNavigate } from 'react-router';
import WhatshotIcon from '@mui/icons-material/Whatshot';
import Chip from '@mui/material/Chip';
import { useAuth } from '../contexts/AuthContext';
import { useNotifications } from '../contexts/NotificationContext';
import { useGamification } from '../contexts/GamificationContext';
import Logo from '../components/common/Logo';
import NotificationPanel from '../components/notifications/NotificationPanel';
import { t } from '../services/TranslationService';
import { useUI } from '../contexts/UIContext';

export default function TopBar() {
  const { userProfile, handleSignOut } = useAuth();
  const navigate = useNavigate();
  const { unreadCount } = useNotifications();
  const { xpTotal, levelName, currentStreak } = useGamification();
  const { isMobile, setMobileDrawerOpen } = useUI();
  const [anchorEl, setAnchorEl] = useState(null);
  const [bellAnchorEl, setBellAnchorEl] = useState(null);

  const displayName = userProfile
    ? [userProfile.first_name, userProfile.last_name].filter(Boolean).join(' ')
    : '';
  const initials = userProfile
    ? [userProfile.first_name?.[0], userProfile.last_name?.[0]].filter(Boolean).join('').toUpperCase()
    : '';

  const handleProfileMenu = (e) => setAnchorEl(e.currentTarget);
  const handleCloseMenu = () => setAnchorEl(null);

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        gridArea: 'topbar',
        zIndex: (theme) => theme.zIndex.drawer + 1,
        borderBottom: '3px solid #F7941D',
        bgcolor: 'background.paper',
        color: 'text.primary',
      }}
    >
      <Toolbar variant="dense" sx={{ minHeight: 56 }}>
        {isMobile && (
          <IconButton
            edge="start"
            onClick={() => setMobileDrawerOpen(true)}
            sx={{ mr: 0.5, color: '#F7941D' }}
          >
            <MenuIcon />
          </IconButton>
        )}
        <Box
          sx={{ display: 'flex', alignItems: 'center', cursor: 'pointer', gap: 1 }}
          onClick={() => navigate('/')}
        >
          <Logo size={26} />
        </Box>

        <Box sx={{ flexGrow: 1 }} />

        {/* Gamification */}
        {!isMobile && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mr: 1 }}>
            <Chip label={levelName} size="small" color="primary" sx={{ fontSize: '0.7rem', height: 22 }} />
            <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>
              {xpTotal.toLocaleString()} XP
            </Typography>
            {currentStreak > 0 && (
              <Tooltip title={`${currentStreak} ${t('gamification.day_streak', 'day streak')}`}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.25 }}>
                  <WhatshotIcon sx={{ fontSize: 16, color: '#F7941D' }} />
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.75rem', color: '#F7941D' }}>
                    {currentStreak}
                  </Typography>
                </Box>
              </Tooltip>
            )}
            <Tooltip title={t('menu.leaderboard', 'Leaderboard')}>
              <IconButton size="small" onClick={() => navigate('/leaderboard')}>
                <EmojiEventsIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        )}

        <Tooltip title={t('menu.notifications', 'Notifications')}>
          <IconButton onClick={(e) => setBellAnchorEl(e.currentTarget)}>
            <Badge badgeContent={unreadCount} color="error" max={99}>
              <NotificationsNoneIcon />
            </Badge>
          </IconButton>
        </Tooltip>
        <NotificationPanel
          anchorEl={bellAnchorEl}
          open={Boolean(bellAnchorEl)}
          onClose={() => setBellAnchorEl(null)}
        />

        {/* Profile menu */}
        <Tooltip title={displayName || t('menu.profile', 'Profile')}>
          <IconButton onClick={handleProfileMenu} sx={{ ml: 0.5 }}>
            <Avatar
              src={userProfile?.avatar_url || undefined}
              sx={{ width: 32, height: 32, fontSize: '0.85rem', bgcolor: 'primary.main' }}
            >
              {initials || <PersonIcon fontSize="small" />}
            </Avatar>
          </IconButton>
        </Tooltip>

        <Menu
          anchorEl={anchorEl}
          open={Boolean(anchorEl)}
          onClose={handleCloseMenu}
          onClick={handleCloseMenu}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        >
          <MenuItem disabled sx={{ opacity: 1 }}>
            <Box>
              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                {displayName}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {userProfile?.email}
              </Typography>
            </Box>
          </MenuItem>
          <Divider />
          <MenuItem onClick={() => navigate('/profile')}>
            <ListItemIcon>
              <PersonIcon fontSize="small" />
            </ListItemIcon>
            {t('menu.profile', 'Profile')}
          </MenuItem>
          <MenuItem onClick={() => navigate('/my-timeline')}>
            <ListItemIcon>
              <TimelineIcon fontSize="small" />
            </ListItemIcon>
            {t('menu.my_timeline', 'My Timeline')}
          </MenuItem>
          <MenuItem onClick={handleSignOut}>
            <ListItemIcon>
              <LogoutIcon fontSize="small" />
            </ListItemIcon>
            {t('ui.sign_out', 'Sign Out')}
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  );
}
