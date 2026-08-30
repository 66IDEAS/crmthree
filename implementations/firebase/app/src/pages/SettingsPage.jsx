import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import usePermissions from '../hooks/usePermissions';
import NotificationPreferencesSection from '../components/settings/NotificationPreferencesSection';
import AccessControlSection from '../components/settings/AccessControlSection';
import UserManagementSection from '../components/settings/UserManagementSection';
import ListSortSection from '../components/settings/ListSortSection';
import RoleManagementSection from '../components/settings/RoleManagementSection';
import ReplicationSection from '../components/settings/ReplicationSection';
import ImportSection from '../components/settings/ImportSection';
import TicketStatusSection from '../components/settings/TicketStatusSection';
import AIProviderSection from '../components/settings/AIProviderSection';
import DataSourceSection from '../components/settings/DataSourceSection';
import LanguageManagementSection from '../components/settings/LanguageManagementSection';
import GamificationSettingsSection from '../components/settings/GamificationSettingsSection';
import { t } from '../services/TranslationService';

export default function SettingsPage() {
  const { isAdmin } = usePermissions();

  return (
    <Box>
      <Typography variant="h5" sx={{ fontWeight: 700, mb: 2 }}>
        {t('settings.title', 'Settings')}
      </Typography>

      <NotificationPreferencesSection />

      {isAdmin && <UserManagementSection />}
      {isAdmin && <ListSortSection />}
      {isAdmin && <RoleManagementSection />}
      {isAdmin && <AccessControlSection />}
      {isAdmin && <GamificationSettingsSection />}
      {isAdmin && <TicketStatusSection />}
      {isAdmin && <AIProviderSection />}
      {isAdmin && <DataSourceSection />}
      {isAdmin && <LanguageManagementSection />}
      {isAdmin && <ImportSection />}
      {isAdmin && <ReplicationSection />}
    </Box>
  );
}
