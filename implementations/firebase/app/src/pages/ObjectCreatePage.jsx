import { useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Alert from '@mui/material/Alert';
import { Link as RouterLink, useParams, useNavigate, useSearchParams } from 'react-router';
import { resolveObjectType, resolveSlug } from '../config/navigation';
import { getObjectLabel } from '../utils/fieldUtils';
import { useMutation } from '../hooks/useDataService';
import ModelRegistry from '../model/ModelRegistry';
import RecordForm from '../components/records/RecordForm';
import { useAuth } from '../contexts/AuthContext';
import { checkAndCreateNotifications } from '../services/NotificationTrigger';
import { checkAndAwardXPForCreate } from '../services/GamificationTrigger';
import { logCreate } from '../services/AuditLogService';
import { t } from '../services/TranslationService';

export default function ObjectCreatePage({ overrideObjectType } = {}) {
  const { objectType: slug } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const objectType = overrideObjectType || resolveObjectType(slug);

  // Extract default values (hidden) and initial data (visible pre-fills) from search params
  const { defaultValues, initialData, returnTo } = useMemo(() => {
    const dv = {};
    const init = {};
    const rt = searchParams.get('_returnTo');
    if (!objectType) return { defaultValues: dv, initialData: init, returnTo: rt };
    const fields = ModelRegistry.getSpecificFields(objectType);
    const fieldNames = new Set(fields.map((f) => f.name));
    for (const [key, value] of searchParams.entries()) {
      if (key.startsWith('_')) continue;
      if (fieldNames.has(key)) {
        dv[key] = value;
      }
    }
    // _prefill_ params are visible pre-fills (not hidden)
    for (const [key, value] of searchParams.entries()) {
      if (key.startsWith('_prefill_')) {
        const fieldName = key.slice(9);
        if (fieldNames.has(fieldName)) {
          init[fieldName] = value;
          delete dv[fieldName]; // ensure not hidden
        }
      }
    }
    return { defaultValues: dv, initialData: init, returnTo: rt };
  }, [objectType, searchParams]);

  const resolvedSlug = slug || resolveSlug(objectType);

  if (!objectType) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{t('ui.unknown_object_type', 'Unknown object type')}: {slug}</Alert>
      </Box>
    );
  }

  return (
    <CreateForm
      objectType={objectType}
      slug={resolvedSlug}
      navigate={navigate}
      defaultValues={defaultValues}
      initialData={initialData}
      returnTo={returnTo}
    />
  );
}

function CreateForm({ objectType, slug, navigate, defaultValues, initialData, returnTo }) {
  const label = getObjectLabel(objectType);
  const { create, loading } = useMutation(objectType);
  const { userProfile } = useAuth();

  const handleSubmit = async (data) => {
    const result = await create(data);
    const recordId = result.id || result;
    // Fire notification and gamification triggers for the newly created record
    try {
      await checkAndCreateNotifications(objectType, recordId, data, {}, userProfile?.id);
    } catch {
      // Notification creation should never block saves
    }
    try {
      await checkAndAwardXPForCreate(objectType, recordId, data, userProfile?.id);
    } catch {
      // Gamification should never block saves
    }
    try {
      await logCreate(objectType, recordId, data, userProfile?.id);
    } catch {
      // Audit logging should never block saves
    }
    if (returnTo) {
      navigate(returnTo, { replace: true });
    } else {
      navigate(`/${slug}/${recordId}`);
    }
  };

  const cancelTo = returnTo || `/${slug}`;

  return (
    <Box>
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link component={RouterLink} to={cancelTo} underline="hover" color="inherit">
          {label}
        </Link>
        <Typography color="text.primary">{t('ui.new', 'New')}</Typography>
      </Breadcrumbs>

      <Typography variant="h5" sx={{ fontWeight: 700, mb: 3 }}>
        {t('ui.new', 'New')} {label.replace(/s$/, '')}
      </Typography>

      <RecordForm
        objectType={objectType}
        initialData={initialData}
        defaultValues={defaultValues}
        onSubmit={handleSubmit}
        onCancel={() => navigate(cancelTo)}
        loading={loading}
      />
    </Box>
  );
}
