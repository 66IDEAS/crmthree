import { useState } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Box from '@mui/material/Box';
import navigationItems from '../../config/navigation';
import { getObjectLabel } from '../../utils/fieldUtils';
import CsvImportDialog from '../records/CsvImportDialog';
import Button from '@mui/material/Button';
import FileUploadIcon from '@mui/icons-material/FileUpload';
import { t } from '../../services/TranslationService';

/**
 * UX35: Data Import Section in Settings (Admin Only).
 * Lets admin select an object type and import records from CSV.
 */
export default function ImportSection() {
  const [objectType, setObjectType] = useState('');
  const [importOpen, setImportOpen] = useState(false);

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.import.title', 'Data Import')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        {t('settings.import.description', 'Import records from a CSV file into any object type. Select the target object and click Import to begin.')}
      </Typography>
      <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          select
          label={t('settings.import.object_type', 'Object Type')}
          value={objectType}
          onChange={(e) => setObjectType(e.target.value)}
          size="small"
          sx={{ minWidth: 220 }}
        >
          {navigationItems.map((item) => (
            <MenuItem key={item.objectType} value={item.objectType}>
              {item.label}
            </MenuItem>
          ))}
        </TextField>
        <Button
          variant="contained"
          startIcon={<FileUploadIcon />}
          disabled={!objectType}
          onClick={() => setImportOpen(true)}
        >
          {t('ui.import_csv', 'Import CSV')}
        </Button>
      </Box>

      {objectType && (
        <CsvImportDialog
          open={importOpen}
          onClose={() => setImportOpen(false)}
          objectType={objectType}
          onComplete={() => setImportOpen(false)}
        />
      )}
    </AccordionDetails>
    </Accordion>
  );
}
