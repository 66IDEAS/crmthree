import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Divider from '@mui/material/Divider';
import Box from '@mui/material/Box';
import Tooltip from '@mui/material/Tooltip';
import MenuIcon from '@mui/icons-material/Menu';
import SettingsIcon from '@mui/icons-material/Settings';
import { useNavigate, useLocation } from 'react-router';
import { useUI } from '../contexts/UIContext';
import { useAuth } from '../contexts/AuthContext';
import navigationItems from '../config/navigation';
import { t } from '../services/TranslationService';

const EXPANDED_WIDTH = 220;
const COLLAPSED_WIDTH = 64;

export default function LeftRibbon() {
  const { ribbonExpanded, toggleRibbon, isMobile, mobileDrawerOpen, setMobileDrawerOpen } = useUI();
  const { role } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const drawerWidth = ribbonExpanded ? EXPANDED_WIDTH : COLLAPSED_WIDTH;
  const showLabels = ribbonExpanded || isMobile;

  // Filter navigation items by role's ribbon_items (UX15)
  const visibleItems = navigationItems.filter(
    (item) => !role?.ribbon_items || role.ribbon_items.includes(item.objectType)
  );

  const handleNav = (path) => {
    navigate(path);
    if (isMobile) setMobileDrawerOpen(false);
  };

  const drawerContent = (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Hamburger toggle */}
      <List disablePadding>
        <ListItem disablePadding sx={{ display: 'block' }}>
          <Tooltip title={showLabels ? '' : t('nav.navigation', 'Navigation')} placement="right" arrow>
            <ListItemButton
              onClick={toggleRibbon}
              sx={{
                minHeight: 44,
                justifyContent: showLabels ? 'initial' : 'center',
                px: 2,
                borderRadius: 1,
                mx: 0.5,
                my: 0.5,
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: 0,
                  mr: showLabels ? 2 : 'auto',
                  justifyContent: 'center',
                  color: '#F7941D',
                }}
              >
                <MenuIcon fontSize="small" />
              </ListItemIcon>
              {showLabels && (
                <ListItemText
                  primary={t('nav.navigation', 'Navigation')}
                  primaryTypographyProps={{
                    fontSize: '0.85rem',
                    fontWeight: 700,
                    color: 'text.primary',
                  }}
                />
              )}
            </ListItemButton>
          </Tooltip>
        </ListItem>
      </List>
      <Divider />

      <List sx={{ flex: 1, pt: 1 }}>
        {visibleItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          return (
            <ListItem key={item.path} disablePadding sx={{ display: 'block' }}>
              <Tooltip title={showLabels ? '' : item.label} placement="right" arrow>
                <ListItemButton
                  onClick={() => handleNav(item.path)}
                  sx={{
                    minHeight: 44,
                    justifyContent: showLabels ? 'initial' : 'center',
                    px: 2,
                    borderRadius: 1,
                    mx: 0.5,
                    mb: 0.25,
                    bgcolor: isActive ? 'action.selected' : 'transparent',
                    '&:hover': { bgcolor: 'action.hover' },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      minWidth: 0,
                      mr: showLabels ? 2 : 'auto',
                      justifyContent: 'center',
                      color: isActive ? 'primary.main' : 'text.secondary',
                    }}
                  >
                    <Icon fontSize="small" />
                  </ListItemIcon>
                  {showLabels && (
                    <ListItemText
                      primary={item.label}
                      primaryTypographyProps={{
                        fontSize: '0.85rem',
                        fontWeight: isActive ? 600 : 400,
                        color: isActive ? 'primary.main' : 'text.primary',
                      }}
                    />
                  )}
                </ListItemButton>
              </Tooltip>
            </ListItem>
          );
        })}
      </List>

      <Divider />

      {/* Settings pinned at bottom */}
      <List>
        <ListItem disablePadding sx={{ display: 'block' }}>
          <Tooltip title={showLabels ? '' : t('nav.settings', 'Settings')} placement="right" arrow>
            <ListItemButton
              onClick={() => handleNav('/settings')}
              sx={{
                minHeight: 44,
                justifyContent: showLabels ? 'initial' : 'center',
                px: 2,
                borderRadius: 1,
                mx: 0.5,
                mb: 0.5,
                bgcolor: location.pathname === '/settings' ? 'action.selected' : 'transparent',
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: 0,
                  mr: showLabels ? 2 : 'auto',
                  justifyContent: 'center',
                  color: location.pathname === '/settings' ? 'primary.main' : 'text.secondary',
                }}
              >
                <SettingsIcon fontSize="small" />
              </ListItemIcon>
              {showLabels && (
                <ListItemText
                  primary={t('nav.settings', 'Settings')}
                  primaryTypographyProps={{ fontSize: '0.85rem' }}
                />
              )}
            </ListItemButton>
          </Tooltip>
        </ListItem>
      </List>
    </Box>
  );

  if (isMobile) {
    return (
      <Drawer
        variant="temporary"
        open={mobileDrawerOpen}
        onClose={() => setMobileDrawerOpen(false)}
        ModalProps={{ keepMounted: true }}
        sx={{
          '& .MuiDrawer-paper': { width: EXPANDED_WIDTH },
        }}
      >
        {drawerContent}
      </Drawer>
    );
  }

  return (
    <Drawer
      variant="permanent"
      sx={{
        gridArea: 'ribbon',
        width: drawerWidth,
        flexShrink: 0,
        transition: 'width 0.2s ease',
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          transition: 'width 0.2s ease',
          position: 'relative',
          overflow: 'hidden',
          borderRight: 1,
          borderColor: 'divider',
        },
      }}
    >
      {drawerContent}
    </Drawer>
  );
}
