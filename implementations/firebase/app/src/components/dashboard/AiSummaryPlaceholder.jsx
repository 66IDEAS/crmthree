import { useState, useEffect, useRef } from 'react';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import CircularProgress from '@mui/material/CircularProgress';
import Collapse from '@mui/material/Collapse';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import RefreshIcon from '@mui/icons-material/Refresh';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ReactMarkdown from 'react-markdown';
import AIService from '../../services/AIService';
import { t } from '../../services/TranslationService';

const SYSTEM_PROMPT =
  'You are a CRM intelligence assistant. Based on the user\'s current CRM dashboard data, provide a concise priority briefing for today. ' +
  'Highlight: items needing immediate attention, key metrics trends, and recommended next actions. ' +
  'Be specific, actionable, and concise. Use 3-5 bullet points.';

function formatCurrency(value) {
  if (value >= 1000000) return `$${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `$${(value / 1000).toFixed(1)}K`;
  return `$${value.toLocaleString()}`;
}

/**
 * Serialize the dashboard data into a compact text block for the AI prompt.
 */
function serializeDashboardContext(data, userName) {
  if (!data) return '';
  const lines = [];
  lines.push(`User: ${userName}`);
  lines.push(`Date: ${new Date().toLocaleDateString()}`);
  lines.push('');
  lines.push('--- Current Dashboard Metrics ---');

  if (data.opportunities) {
    lines.push(`Open Opportunities: ${data.opportunities.open} of ${data.opportunities.total} total`);
    lines.push(`Pipeline Value: ${formatCurrency(data.opportunities.pipelineValue || 0)}`);
    if (data.opportunities.byStage?.length) {
      lines.push(`Opportunities by Stage: ${data.opportunities.byStage.map((s) => `${s.name}: ${s.value}`).join(', ')}`);
    }
  }

  if (data.leads) {
    lines.push(`Open Leads: ${data.leads.open} of ${data.leads.total} total`);
    lines.push(`Lead Conversion Rate: ${data.leads.conversionRate || 0}%`);
  }

  if (data.tickets) {
    lines.push(`Open Tickets: ${data.tickets.open} of ${data.tickets.total} total`);
    if (data.tickets.byPriority?.length) {
      lines.push(`Tickets by Priority: ${data.tickets.byPriority.map((p) => `${p.name}: ${p.value}`).join(', ')}`);
    }
  }

  if (data.activities) {
    lines.push(`Activities This Week: ${data.activities.thisWeek} of ${data.activities.total} total`);
  }

  if (data.invoices) {
    lines.push(`Total Invoices: ${data.invoices.total}`);
    if (data.invoices.revenueByStatus?.length) {
      lines.push(`Revenue by Status: ${data.invoices.revenueByStatus.map((r) => `${r.name}: ${formatCurrency(r.value)}`).join(', ')}`);
    }
  }

  if (data.quotations) {
    lines.push(`Total Quotations: ${data.quotations.total}`);
  }

  return lines.join('\n');
}

/**
 * UX13 + F22 (User level): AI-powered priority summary on the home screen.
 * Shows a placeholder when no AI provider is configured; otherwise allows
 * the user to generate a personalized priority briefing from dashboard data.
 */
export default function AiSummaryPlaceholder({ dashboardData, userName }) {
  const [summary, setSummary] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [collapsed, setCollapsed] = useState(false);
  const [aiConfigured, setAiConfigured] = useState(null); // null = checking
  const fetchIdRef = useRef(0);

  useEffect(() => {
    AIService.isConfigured().then(setAiConfigured).catch(() => setAiConfigured(false));
  }, []);

  const handleGenerate = () => {
    setSummary('');
    setError(null);
    const currentId = ++fetchIdRef.current;
    setLoading(true);

    const context = serializeDashboardContext(dashboardData, userName);

    AIService.chat([
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: `Here is my current CRM dashboard:\n\n${context}\n\nGenerate my priority briefing for today.` },
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

  // Still checking AI config
  if (aiConfigured === null) return null;

  // No AI configured — show placeholder
  if (!aiConfigured) {
    return (
      <Paper
        sx={{
          p: 3,
          display: 'flex',
          alignItems: 'center',
          gap: 2,
          bgcolor: 'action.hover',
        }}
      >
        <AutoAwesomeIcon sx={{ color: '#F7941D', fontSize: 32 }} />
        <Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {t('dashboard.ai_summary', 'AI Priority Summary')}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {t('dashboard.ai_summary_placeholder', 'Your personalized AI-powered priority summary will appear here once an AI provider is configured.')}
          </Typography>
        </Box>
      </Paper>
    );
  }

  // AI configured — show functional summary card
  const hasContent = summary || loading || error;

  return (
    <Paper
      elevation={0}
      sx={{
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
          {t('dashboard.ai_summary', 'AI Priority Summary')}
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
              <Box
                sx={{
                  '& p': { m: 0, mb: 1, lineHeight: 1.7, fontSize: '0.875rem' },
                  '& p:last-child': { mb: 0 },
                  '& ul, & ol': { m: 0, pl: 2.5, mb: 1 },
                  '& li': { lineHeight: 1.7, fontSize: '0.875rem', mb: 0.5 },
                  '& strong': { fontWeight: 600 },
                  color: 'text.primary',
                }}
              >
                <ReactMarkdown>{summary}</ReactMarkdown>
              </Box>
            )}
          </Box>
        </Collapse>
      )}
    </Paper>
  );
}
