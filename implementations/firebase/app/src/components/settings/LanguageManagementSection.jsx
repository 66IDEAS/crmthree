import { useState, useEffect, useMemo } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import Autocomplete from '@mui/material/Autocomplete';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import LinearProgress from '@mui/material/LinearProgress';
import Chip from '@mui/material/Chip';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import { listTranslationDocs, saveTranslationDoc, deleteTranslationDoc } from '../../services/TranslationStore';
import { getAllLabels } from '../../config/labels';
import AVAILABLE_LANGUAGES from '../../config/languages';
import AIService from '../../services/AIService';
import { t } from '../../services/TranslationService';

/**
 * UX35/F60: Admin-only Settings section for managing UI translations.
 */
export default function LanguageManagementSection() {
  const [languages, setLanguages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [addOpen, setAddOpen] = useState(false);
  const [selectedLang, setSelectedLang] = useState(null);
  const [editorOpen, setEditorOpen] = useState(false);
  const [editingLang, setEditingLang] = useState(null);
  const [editLabels, setEditLabels] = useState({});
  const [saving, setSaving] = useState(false);
  const [translating, setTranslating] = useState(false);
  const [translateProgress, setTranslateProgress] = useState('');
  const [searchFilter, setSearchFilter] = useState('');
  const [categoryTab, setCategoryTab] = useState(0);

  const allLabels = useMemo(() => getAllLabels(), []);
  const allKeys = useMemo(() => Object.keys(allLabels).sort(), [allLabels]);

  useEffect(() => {
    loadLanguages();
  }, []);

  const loadLanguages = async () => {
    setLoading(true);
    try {
      const docs = await listTranslationDocs();
      setLanguages(docs);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Configured language codes
  const configuredCodes = new Set(languages.map((l) => l.language_code));

  // Available languages for add dialog (not yet configured)
  const availableForAdd = AVAILABLE_LANGUAGES.filter((l) => !configuredCodes.has(l.code));

  const handleAddLanguage = async () => {
    if (!selectedLang) return;
    setSaving(true);
    try {
      await saveTranslationDoc(selectedLang.code, {
        language_code: selectedLang.code,
        language_name: selectedLang.name,
        labels: {},
      });
      setAddOpen(false);
      setSelectedLang(null);
      loadLanguages();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteLanguage = async (lang) => {
    try {
      await deleteTranslationDoc(lang.language_code);
      loadLanguages();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleManage = (lang) => {
    setEditingLang(lang);
    setEditLabels({ ...(lang.labels || {}) });
    setSearchFilter('');
    setCategoryTab(0);
    setEditorOpen(true);
  };

  const handleSaveTranslations = async () => {
    setSaving(true);
    try {
      await saveTranslationDoc(editingLang.language_code, {
        language_code: editingLang.language_code,
        language_name: editingLang.language_name,
        labels: editLabels,
      });
      setEditorOpen(false);
      setEditingLang(null);
      loadLanguages();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAITranslate = async () => {
    const aiConfigured = await AIService.isConfigured();
    if (!aiConfigured) {
      setError('No AI provider is configured. Please configure one in the AI Provider section above.');
      return;
    }

    setTranslating(true);
    setError(null);

    // Collect untranslated labels
    const untranslated = {};
    for (const key of allKeys) {
      if (!editLabels[key]) {
        untranslated[key] = allLabels[key];
      }
    }

    const untranslatedKeys = Object.keys(untranslated);
    if (untranslatedKeys.length === 0) {
      setTranslating(false);
      return;
    }

    // Batch into groups of 50
    const batchSize = 50;
    const batches = [];
    for (let i = 0; i < untranslatedKeys.length; i += batchSize) {
      const batchKeys = untranslatedKeys.slice(i, i + batchSize);
      const batch = {};
      batchKeys.forEach((k) => { batch[k] = untranslated[k]; });
      batches.push(batch);
    }

    let currentLabels = { ...editLabels };
    let successCount = 0;
    let failedBatches = 0;

    for (let i = 0; i < batches.length; i++) {
      setTranslateProgress(`Translating batch ${i + 1} of ${batches.length}... (${successCount} labels so far)`);
      try {
        const batchJson = JSON.stringify(batches[i], null, 2);
        const prompt = `Translate the following English UI labels to ${editingLang.language_name} (${editingLang.language_code}). Return ONLY a valid JSON object with the exact same keys and translated values. Keep translations concise and appropriate for a CRM application UI. Do not translate proper nouns or technical terms that should remain in English.\n\n${batchJson}`;

        const result = await AIService.generate(prompt);
        // Parse the JSON response
        let parsed;
        try {
          let content = result.content || '';
          // Strip markdown code fences if present
          content = content.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
          parsed = JSON.parse(content);
        } catch {
          failedBatches++;
          continue; // Skip batch on parse error
        }

        // Merge translations
        for (const [key, value] of Object.entries(parsed)) {
          if (key in allLabels && typeof value === 'string') {
            currentLabels[key] = value;
            successCount++;
          }
        }

        // Update state after each batch so progress is visible
        setEditLabels({ ...currentLabels });
      } catch {
        failedBatches++;
        // Continue with next batch on error
      }

      // Small delay between batches to avoid rate limiting
      if (i < batches.length - 1) {
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
    }

    setEditLabels(currentLabels);
    const failedMsg = failedBatches > 0 ? ` (${failedBatches} batch${failedBatches > 1 ? 'es' : ''} failed)` : '';
    setTranslateProgress(`Translated ${successCount} labels.${failedMsg}`);
    setTranslating(false);
  };

  // Category filters
  const categories = [
    { label: t('settings.language.all', 'All'), prefix: '' },
    { label: t('settings.language.category_nav', 'Navigation'), prefix: 'nav.' },
    { label: t('settings.language.category_fields', 'Fields'), prefix: 'field.' },
    { label: t('settings.language.category_enums', 'Enums'), prefix: 'enum.' },
    { label: t('settings.language.category_ui', 'UI'), prefix: 'ui.' },
    { label: t('settings.language.category_other', 'Other'), prefix: '_other' },
  ];

  const filteredKeys = useMemo(() => {
    const cat = categories[categoryTab];
    return allKeys.filter((key) => {
      // Category filter
      if (cat.prefix === '_other') {
        const knownPrefixes = ['nav.', 'field.', 'enum.', 'ui.', 'object.', 'rel.'];
        if (knownPrefixes.some((p) => key.startsWith(p))) return false;
      } else if (cat.prefix && !key.startsWith(cat.prefix)) {
        return false;
      }
      // Search filter
      if (searchFilter) {
        const q = searchFilter.toLowerCase();
        return key.toLowerCase().includes(q) || (allLabels[key] || '').toLowerCase().includes(q);
      }
      return true;
    });
  }, [allKeys, allLabels, categoryTab, searchFilter]); // eslint-disable-line react-hooks/exhaustive-deps

  const translatedCount = allKeys.filter((k) => editLabels[k]).length;

  // Count translated labels per language for the overview table
  const getTranslatedCount = (lang) => {
    const labels = lang.labels || {};
    return Object.keys(labels).filter((k) => labels[k]).length;
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.language.title', 'Language Management')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="body2" color="text.secondary">
          {t('settings.language.description', 'Manage UI translations. Add languages and translate all labels using AI or manually.')}
        </Typography>
        <Button variant="outlined" size="small" startIcon={<AddIcon />} onClick={() => setAddOpen(true)}>
          {t('settings.language.add', 'Add Language')}
        </Button>
      </Box>

      {error && !editorOpen && !addOpen && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </Box>
      ) : languages.length === 0 ? (
        <Typography variant="body2" color="text.secondary">
          {t('settings.language.empty', 'No languages configured. Click "Add Language" to get started.')}
        </Typography>
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('settings.language.language', 'Language')}</TableCell>
                <TableCell>{t('settings.language.code', 'Code')}</TableCell>
                <TableCell>{t('settings.language.translated', 'Labels Translated')}</TableCell>
                <TableCell align="right">{t('ui.actions', 'Actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {languages.map((lang) => (
                <TableRow key={lang.language_code}>
                  <TableCell>{lang.language_name}</TableCell>
                  <TableCell><Chip label={lang.language_code} size="small" /></TableCell>
                  <TableCell>{getTranslatedCount(lang)} / {allKeys.length}</TableCell>
                  <TableCell align="right">
                    <IconButton size="small" onClick={() => handleManage(lang)} title={t('settings.language.manage', 'Manage')}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" onClick={() => handleDeleteLanguage(lang)} title={t('ui.delete', 'Delete')}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Add Language Dialog */}
      <Dialog open={addOpen} onClose={() => setAddOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>{t('settings.language.add_title', 'Add Language')}</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 1 }}>
            <Autocomplete
              options={availableForAdd}
              getOptionLabel={(opt) => opt.name}
              value={selectedLang}
              onChange={(_, val) => setSelectedLang(val)}
              renderInput={(params) => (
                <TextField {...params} label={t('settings.language.select', 'Select a language')} size="small" />
              )}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddOpen(false)}>{t('ui.cancel', 'Cancel')}</Button>
          <Button variant="contained" onClick={handleAddLanguage} disabled={!selectedLang || saving}>
            {saving ? <CircularProgress size={20} /> : t('ui.add', 'Add')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Label Editor Dialog */}
      <Dialog open={editorOpen} onClose={() => setEditorOpen(false)} maxWidth="lg" fullWidth>
        <DialogTitle>
          {t('settings.language.manage_title', 'Manage Translations')} — {editingLang?.language_name} ({editingLang?.language_code})
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            {error && editorOpen && <Alert severity="error">{error}</Alert>}

            {/* Progress */}
            <Box>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                {translatedCount} / {allKeys.length} {t('settings.language.translated', 'labels translated')} ({allKeys.length > 0 ? Math.round((translatedCount / allKeys.length) * 100) : 0}%)
              </Typography>
              <LinearProgress
                variant="determinate"
                value={allKeys.length > 0 ? (translatedCount / allKeys.length) * 100 : 0}
                sx={{ height: 6, borderRadius: 3 }}
              />
            </Box>

            {/* Search + AI Translate */}
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
              <TextField
                size="small"
                placeholder={t('settings.language.search', 'Filter labels...')}
                value={searchFilter}
                onChange={(e) => setSearchFilter(e.target.value)}
                sx={{ flex: 1 }}
              />
              <Button
                variant="outlined"
                startIcon={translating ? <CircularProgress size={16} /> : <AutoAwesomeIcon />}
                onClick={handleAITranslate}
                disabled={translating}
              >
                {translating ? t('settings.language.translating', 'Translating...') : t('settings.language.ai_translate', 'AI Translate All')}
              </Button>
            </Box>

            {translateProgress && (
              <Typography variant="caption" color="text.secondary">{translateProgress}</Typography>
            )}

            {/* Category Tabs */}
            <Tabs value={categoryTab} onChange={(_, v) => setCategoryTab(v)} variant="scrollable" scrollButtons="auto">
              {categories.map((cat, i) => (
                <Tab key={i} label={cat.label} />
              ))}
            </Tabs>

            {/* Labels Table */}
            <TableContainer sx={{ maxHeight: 400 }}>
              <Table size="small" stickyHeader>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ width: '30%' }}>{t('settings.language.key', 'Label Key')}</TableCell>
                    <TableCell sx={{ width: '30%' }}>{t('settings.language.english', 'English')}</TableCell>
                    <TableCell sx={{ width: '40%' }}>{editingLang?.language_name}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredKeys.slice(0, 200).map((key) => (
                    <TableRow key={key}>
                      <TableCell>
                        <Typography variant="caption" sx={{ fontFamily: 'monospace', fontSize: '0.7rem' }}>
                          {key}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {allLabels[key]}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          fullWidth
                          value={editLabels[key] || ''}
                          onChange={(e) => setEditLabels((prev) => ({ ...prev, [key]: e.target.value }))}
                          variant="standard"
                          placeholder={allLabels[key]}
                          sx={{
                            '& .MuiInput-input': { fontSize: '0.875rem' },
                          }}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            {filteredKeys.length > 200 && (
              <Typography variant="caption" color="text.secondary">
                Showing 200 of {filteredKeys.length} labels. Use the filter to narrow results.
              </Typography>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditorOpen(false)}>{t('ui.cancel', 'Cancel')}</Button>
          <Button variant="contained" onClick={handleSaveTranslations} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : t('ui.save', 'Save')}
          </Button>
        </DialogActions>
      </Dialog>
    </AccordionDetails>
    </Accordion>
  );
}
