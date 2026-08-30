import { useState, useEffect, useRef } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import CircularProgress from '@mui/material/CircularProgress';
import Collapse from '@mui/material/Collapse';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import RefreshIcon from '@mui/icons-material/Refresh';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ModelRegistry from '../../model/ModelRegistry';
import AIService from '../../services/AIService';
import { t } from '../../services/TranslationService';

const SUMMARY_ENABLED_TYPES = new Set([
  'Account', 'Contact', 'Lead', 'Opportunity', 'Ticket',
  'Quotation', 'SalesOrder', 'Invoice',
]);

const SUMMARY_PROMPTS = {
  Account: 'You are a CRM intelligence assistant. Analyze this account record and its related CRM data. Provide a concise executive briefing covering: relationship health, recent activity patterns, open pipeline value, and any signals that need attention. Be specific and actionable. Keep it to 3-5 sentences.',
  Contact: 'You are a CRM intelligence assistant. Analyze this contact record and its related CRM data. Provide a concise briefing covering: role and influence, recent interactions, associated open items (opportunities, tickets), and communication patterns. Be specific. Keep it to 3-5 sentences.',
  Opportunity: 'You are a CRM intelligence assistant. Analyze this opportunity and its related CRM data. Provide a concise deal status briefing covering: current stage assessment, risk factors, next best actions, and timeline health. Be specific and actionable. Keep it to 3-5 sentences.',
  Lead: 'You are a CRM intelligence assistant. Analyze this lead record. Provide a concise qualification briefing covering: lead quality assessment, engagement signals, recommended actions, and conversion readiness. Keep it to 3-5 sentences.',
  Ticket: 'You are a CRM intelligence assistant. Analyze this support ticket and its related CRM data. Provide a concise case briefing covering: issue severity, SLA status, customer context, and recommended resolution approach. Keep it to 3-5 sentences.',
  Quotation: 'You are a CRM intelligence assistant. Analyze this quotation record and its related CRM data. Provide a concise briefing covering: quote status, total value, validity, and any concerns or recommended next steps. Keep it to 3-5 sentences.',
  SalesOrder: 'You are a CRM intelligence assistant. Analyze this sales order record and its related CRM data. Provide a concise briefing covering: order status, fulfillment, total value, and any items needing attention. Keep it to 3-5 sentences.',
  Invoice: 'You are a CRM intelligence assistant. Analyze this invoice record and its related CRM data. Provide a concise briefing covering: payment status, total amount, due date, and any collection concerns. Keep it to 3-5 sentences.',
};

const DEFAULT_PROMPT = 'You are a CRM intelligence assistant. Provide a concise contextual summary of this record, highlighting key information, current status, and any items that need attention. Keep it to 3-5 sentences.';

/**
 * Serialize a record's fields into human-readable text for the AI prompt.
 */
function serializeRecord(objectType, record) {
  const fields = ModelRegistry.getSpecificFields(objectType);
  const lines = [];
  for (const field of fields) {
    const val = record[field.name];
    if (val === undefined || val === null || val === '') continue;
    const label = field.description || field.name;
    lines.push(`${label}: ${val}`);
  }
  return lines.join('\n');
}

/**
 * UX7 + F21: AI-generated contextual briefing displayed on record detail pages.
 */
export default function AiRecordSummary({ objectType, record }) {
  const [summary, setSummary] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [collapsed, setCollapsed] = useState(false);
  const [aiConfigured, setAiConfigured] = useState(false);
  const fetchIdRef = useRef(0);

  // Check AI configuration on mount
  useEffect(() => {
    AIService.isConfigured().then(setAiConfigured).catch(() => setAiConfigured(false));
  }, []);

  // Don't render if AI is not configured or object type not supported
  if (!aiConfigured || !SUMMARY_ENABLED_TYPES.has(objectType)) return null;

  const handleGenerate = () => {
    setSummary('');
    setError(null);
    const currentId = ++fetchIdRef.current;
    setLoading(true);

    const systemPrompt = SUMMARY_PROMPTS[objectType] || DEFAULT_PROMPT;
    const recordText = serializeRecord(objectType, record);
    const relatedHint = {
      Account: 'Consider related contacts, opportunities, activities, and tickets.',
      Contact: 'Consider related accounts, opportunities, activities, and tickets.',
      Opportunity: 'Consider the related account, contacts, and activities.',
      Lead: 'Consider any related activities.',
      Ticket: 'Consider the related account, contact, and activities.',
    };
    const hint = relatedHint[objectType] || '';

    AIService.chat([
      { role: 'system', content: systemPrompt },
      { role: 'user', content: `Here is the ${objectType} record:\n\n${recordText}\n\n${hint}\n\nGenerate a contextual intelligence briefing.` },
    ])
      .then((response) => {
        if (currentId === fetchIdRef.current) setSummary(response.content);
      })
      .catch((err) => {
        if (currentId === fetchIdRef.current) setError(err.message || 'Failed to generate briefing');
      })
      .finally(() => {
        if (currentId === fetchIdRef.current) setLoading(false);
      });
  };

  const hasContent = summary || loading || error;

  return (
    <Paper
      elevation={0}
      sx={{
        mx: 2,
        mt: 1,
        mb: 1,
        p: 2,
        bgcolor: 'action.hover',
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Avatar sx={{ width: 32, height: 32, bgcolor: '#F7941D', flexShrink: 0 }}>
          <AutoAwesomeIcon sx={{ fontSize: 18, color: '#fff' }} />
        </Avatar>
        <Typography variant="subtitle2" sx={{ fontWeight: 700, flex: 1 }}>
          {t('ai.briefing', 'AI Briefing')}
        </Typography>
        {!hasContent && (
          <Button
            size="small"
            variant="outlined"
            startIcon={<AutoAwesomeIcon />}
            onClick={handleGenerate}
            sx={{ textTransform: 'none', fontSize: '0.8rem' }}
          >
            {t('ai.generate', 'Generate Briefing')}
          </Button>
        )}
        {hasContent && (
          <>
            <IconButton size="small" onClick={handleGenerate} disabled={loading} title={t('ai.regenerate', 'Regenerate')}>
              <RefreshIcon fontSize="small" />
            </IconButton>
            <IconButton size="small" onClick={() => setCollapsed((c) => !c)} title={collapsed ? t('ai.expand', 'Expand') : t('ai.collapse', 'Collapse')}>
              {collapsed ? <ExpandMoreIcon fontSize="small" /> : <ExpandLessIcon fontSize="small" />}
            </IconButton>
          </>
        )}
      </Box>

      {hasContent && (
        <Collapse in={!collapsed}>
          <Box sx={{ mt: 1, pl: 5.5 }}>
            {loading && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, py: 1 }}>
                <CircularProgress size={16} sx={{ color: '#F7941D' }} />
                <Typography variant="body2" color="text.secondary">
                  {t('ai.generating', 'Generating briefing...')}
                </Typography>
              </Box>
            )}
            {error && !loading && (
              <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                {error}
              </Typography>
            )}
            {summary && !loading && (
              <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap', lineHeight: 1.7, color: 'text.primary' }}>
                {summary}
              </Typography>
            )}
          </Box>
        </Collapse>
      )}
    </Paper>
  );
}
