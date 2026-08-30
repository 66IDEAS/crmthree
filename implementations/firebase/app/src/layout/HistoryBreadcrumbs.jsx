import { useState } from 'react';
import Box from '@mui/material/Box';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemText from '@mui/material/ListItemText';
import ArrowDropDownIcon from '@mui/icons-material/ArrowDropDown';
import { useNavigate } from 'react-router';
import { useNavigationHistory } from '../contexts/NavigationHistoryContext';

const VISIBLE_COUNT = 5;
const DROPDOWN_COUNT = 10;

export default function HistoryBreadcrumbs() {
  const { history } = useNavigationHistory();
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = useState(null);

  if (history.length === 0) return null;

  const visibleItems = history.slice(-VISIBLE_COUNT);
  const overflowItems = history.slice(0, -VISIBLE_COUNT).reverse().slice(0, DROPDOWN_COUNT);

  const handleNavigate = (path) => {
    setAnchorEl(null);
    navigate(path);
  };

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        mb: 2,
        minHeight: 24,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap' }}>
        {visibleItems.map((entry, idx) => {
          const isLast = idx === visibleItems.length - 1;
          return (
            <Box key={`${entry.path}-${idx}`} component="span" sx={{ display: 'inline-flex', alignItems: 'center' }}>
              {idx > 0 && (
                <Typography variant="body2" color="text.secondary" sx={{ mx: 0.5 }}>
                  /
                </Typography>
              )}
              {isLast ? (
                <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
                  {entry.label}
                </Typography>
              ) : (
                <Link
                  component="button"
                  variant="body2"
                  underline="hover"
                  color="text.secondary"
                  onClick={() => handleNavigate(entry.path)}
                  sx={{ cursor: 'pointer' }}
                >
                  {entry.label}
                </Link>
              )}
            </Box>
          );
        })}
      </Box>

      {overflowItems.length > 0 && (
        <>
          <IconButton
            size="small"
            onClick={(e) => setAnchorEl(e.currentTarget)}
            sx={{ ml: 0.5 }}
          >
            <ArrowDropDownIcon fontSize="small" />
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={() => setAnchorEl(null)}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
          >
            {overflowItems.map((entry, idx) => (
              <MenuItem
                key={`${entry.path}-${idx}`}
                onClick={() => handleNavigate(entry.path)}
                dense
              >
                <ListItemText primary={entry.label} />
              </MenuItem>
            ))}
          </Menu>
        </>
      )}
    </Box>
  );
}
