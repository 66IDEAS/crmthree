import { useState, useEffect, useRef, useCallback } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListSubheader from '@mui/material/ListSubheader';
import CircularProgress from '@mui/material/CircularProgress';
import Chip from '@mui/material/Chip';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import Avatar from '@mui/material/Avatar';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import PersonIcon from '@mui/icons-material/Person';
import { useNavigate } from 'react-router';
import navigationItems, { resolveSlug } from '../config/navigation';
import ModelRegistry from '../model/ModelRegistry';
import DataService from '../services/DataService';
import AIService from '../services/AIService';
import { useAuth } from '../contexts/AuthContext';
import { getDisplayName, formatAutoNumber, getAutoNumberField } from '../utils/fieldUtils';
import { t } from '../services/TranslationService';
import { useUI } from '../contexts/UIContext';

/** Question words that signal an AI query */
const QUESTION_WORDS = new Set([
  'who', 'what', 'where', 'when', 'why', 'how', 'which',
  'can', 'could', 'should', 'is', 'are', 'do', 'does',
  'list', 'show', 'find', 'summarize', 'explain', 'help',
]);

/**
 * Detect whether an input looks like an AI query vs a keyword search.
 * Returns true for AI queries.
 */
function isAIQuery(input) {
  const trimmed = input.trim();
  if (!trimmed) return false;
  // Contains a question mark
  if (trimmed.includes('?')) return true;
  // Starts with a question word
  const firstWord = trimmed.split(/\s+/)[0].toLowerCase();
  if (QUESTION_WORDS.has(firstWord)) return true;
  // 4+ words = natural language
  const wordCount = trimmed.split(/\s+/).length;
  if (wordCount >= 4) return true;
  return false;
}

/** Words that signal a conversational (chat) intent rather than a search intent */
const CHAT_WORDS = new Set([
  'what', 'why', 'how', 'when', 'explain', 'summarize', 'help',
  'can', 'could', 'should', 'is', 'are', 'do', 'does', 'tell',
]);

/**
 * F23: Detect whether an AI query is a search intent (find records)
 * vs. a conversational intent (ask a question).
 * Returns true for search intent.
 */
function isSearchIntent(input) {
  const trimmed = input.trim().toLowerCase();
  // Explicit question mark = conversational
  if (trimmed.endsWith('?')) return false;
  const firstWord = trimmed.split(/\s+/)[0];
  // Starts with a chat/question word = conversational
  if (CHAT_WORDS.has(firstWord)) return false;
  // Everything else that passes isAIQuery = search intent
  return true;
}

/**
 * F16 + F20 + F23 + UX19: Global search bar with chat-style AI conversation,
 * semantic search, and keyword search drop-up panel.
 */
export default function AISearchBar() {
  const navigate = useNavigate();
  const { userProfile } = useAuth();
  const { isMobile } = useUI();
  const initials = userProfile
    ? [userProfile.first_name?.[0], userProfile.last_name?.[0]].filter(Boolean).join('').toUpperCase()
    : '';
  const [query, setQuery] = useState('');
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [chatMessages, setChatMessages] = useState([]);
  const [aiLoading, setAiLoading] = useState(false);
  const [semanticLoading, setSemanticLoading] = useState(false);
  const [isSemanticResult, setIsSemanticResult] = useState(false);
  const [aiConfigured, setAiConfigured] = useState(false);
  const inputRef = useRef(null);
  const searchIdRef = useRef(0);
  const chatEndRef = useRef(null);

  // Check if AI is configured (on mount + periodically refresh)
  useEffect(() => {
    const check = () => AIService.isConfigured().then(setAiConfigured).catch(() => setAiConfigured(false));
    check();
    const interval = setInterval(check, 30000); // re-check every 30s
    return () => clearInterval(interval);
  }, []);

  // Auto-scroll chat to bottom when new messages arrive
  useEffect(() => {
    if (chatMessages.length > 0 || aiLoading) {
      chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [chatMessages, aiLoading]);

  // Debounced keyword search
  useEffect(() => {
    if (query.trim().length < 2) {
      setResults(null);
      return;
    }

    setLoading(true);
    const currentId = ++searchIdRef.current;
    const timer = setTimeout(() => {
      performSearch(query.trim().toLowerCase(), currentId);
    }, 400);

    return () => clearTimeout(timer);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query]);

  const performSearch = useCallback(async (term, searchId) => {
    const grouped = {};

    await Promise.all(
      navigationItems.map(async (navItem) => {
        try {
          const objectType = navItem.objectType;
          const fields = ModelRegistry.getSpecificFields(objectType);
          const stringFields = fields.filter(
            (f) => (f.type === 'string' || f.type === 'text') && !f.primary_key
          );
          if (stringFields.length === 0) return;

          const records = await DataService.list(objectType, { pageSize: 100 });

          const matches = records.filter((record) =>
            stringFields.some((field) => {
              const val = record[field.name];
              return val && String(val).toLowerCase().includes(term);
            })
          );

          if (matches.length > 0 && searchId === searchIdRef.current) {
            grouped[objectType] = matches.slice(0, 5).map((record) => {
              const autoField = getAutoNumberField(fields);
              const autoNum = autoField && record[autoField.name]
                ? formatAutoNumber(record[autoField.name])
                : null;
              return {
                id: record.id,
                displayName: getDisplayName(record, fields),
                autoNumber: autoNum,
                slug: navItem.path.slice(1),
              };
            });
          }
        } catch {
          // Skip failed types
        }
      })
    );

    if (searchId === searchIdRef.current) {
      setResults(grouped);
      setLoading(false);
    }
  }, []);

  // Ctrl+K / Cmd+K keyboard shortcut
  useEffect(() => {
    const handler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, []);

  const handleSelect = (slug, id) => {
    navigate(`/${slug}/${id}`);
    setQuery('');
    setResults(null);
    setChatMessages([]);
    setIsSemanticResult(false);
    inputRef.current?.blur();
  };

  const handleClose = () => {
    setResults(null);
    setChatMessages([]);
    setIsSemanticResult(false);
  };

  const handleKeyDown = async (e) => {
    if (e.key === 'Escape') {
      setResults(null);
      setChatMessages([]);
      setIsSemanticResult(false);
      setQuery('');
      inputRef.current?.blur();
      return;
    }

    // On Enter: check if this looks like an AI query
    if (e.key === 'Enter' && query.trim() && isAIQuery(query)) {
      // Fresh check — works immediately after configuring a provider
      AIService.clearCache();
      const configured = await AIService.isConfigured();
      setAiConfigured(configured);
      if (!configured) return;
      e.preventDefault();

      const trimmedQuery = query.trim();

      // F23: Semantic search for search-intent queries
      if (isSearchIntent(trimmedQuery)) {
        setQuery('');
        setSemanticLoading(true);
        setIsSemanticResult(true);
        setResults(null);

        try {
          const response = await AIService.semanticSearch(trimmedQuery);
          const grouped = {};
          for (const result of (response.results || [])) {
            const slug = resolveSlug(result.type);
            if (!slug) continue;
            if (!grouped[result.type]) grouped[result.type] = [];
            grouped[result.type].push({
              id: result.id,
              displayName: result.name || 'Untitled',
              autoNumber: null,
              slug,
              reason: result.reason,
            });
          }
          setResults(grouped);
        } catch (err) {
          setChatMessages((prev) => [
            ...prev,
            { role: 'assistant', content: `Search failed: ${err.message || 'AI search request failed'}` },
          ]);
        } finally {
          setSemanticLoading(false);
        }
        return;
      }

      // Chat path for conversational queries
      const userMessage = { role: 'user', content: trimmedQuery };
      const updatedMessages = [...chatMessages, userMessage];
      setChatMessages(updatedMessages);
      setQuery('');
      setAiLoading(true);
      setIsSemanticResult(false);

      try {
        const response = await AIService.chat([
          {
            role: 'system',
            content: 'You are a CRM assistant helping users with their sales and service data. Be concise.',
          },
          ...updatedMessages,
        ]);
        setChatMessages((prev) => [...prev, { role: 'assistant', content: response.content }]);
      } catch (err) {
        setChatMessages((prev) => [
          ...prev,
          { role: 'assistant', content: `Error: ${err.message || 'AI request failed'}` },
        ]);
      } finally {
        setAiLoading(false);
      }
    }
  };

  const hasResults = results && Object.keys(results).length > 0;
  const hasChat = chatMessages.length > 0 || aiLoading;
  const showPanel = results !== null || loading || semanticLoading || hasChat;

  return (
    <ClickAwayListener onClickAway={handleClose}>
      <Paper
        elevation={0}
        sx={{
          gridArea: 'aibar',
          display: 'flex',
          alignItems: 'center',
          px: 2,
          gap: 1.5,
          borderTop: 1,
          borderColor: 'divider',
          borderRadius: 0,
          zIndex: (theme) => theme.zIndex.drawer + 1,
          position: 'relative',
        }}
      >
        {/* Drop-up results panel */}
        {showPanel && (
          <Paper
            elevation={8}
            sx={{
              position: 'absolute',
              bottom: '100%',
              left: 0,
              right: 0,
              maxHeight: isMobile ? 320 : 480,
              overflowY: 'auto',
              borderRadius: '8px 8px 0 0',
              border: 1,
              borderColor: 'divider',
              borderBottom: 'none',
            }}
          >
            {/* Chat Thread */}
            {hasChat && (
              <Box
                sx={{
                  py: 2,
                  px: isMobile ? 2 : 6,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 1.5,
                  borderBottom: hasResults || loading ? 1 : 0,
                  borderColor: 'divider',
                }}
              >
                {chatMessages.map((msg, idx) =>
                  msg.role === 'user' ? (
                    <Box key={idx} sx={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'flex-start', gap: 1 }}>
                      <Box
                        sx={{
                          bgcolor: 'primary.main',
                          px: 2,
                          py: 1,
                          borderRadius: '16px 16px 4px 16px',
                          maxWidth: '65%',
                        }}
                      >
                        <Typography variant="body2" sx={{ color: '#fff' }}>{msg.content}</Typography>
                      </Box>
                      <Avatar
                        src={userProfile?.avatar_url || undefined}
                        sx={{ width: 28, height: 28, fontSize: '0.7rem', bgcolor: 'primary.main', flexShrink: 0 }}
                      >
                        {initials || <PersonIcon sx={{ fontSize: 16 }} />}
                      </Avatar>
                    </Box>
                  ) : (
                    <Box key={idx} sx={{ display: 'flex', justifyContent: 'flex-start', alignItems: 'flex-start', gap: 1 }}>
                      <Avatar sx={{ width: 28, height: 28, bgcolor: '#F7941D', flexShrink: 0 }}>
                        <AutoAwesomeIcon sx={{ fontSize: 16, color: '#fff' }} />
                      </Avatar>
                      <Box sx={{ maxWidth: '70%' }}>
                        <Box
                          sx={{
                            bgcolor: 'action.hover',
                            px: 2,
                            py: 1,
                            borderRadius: '16px 16px 16px 4px',
                          }}
                        >
                          <Typography
                            variant="body2"
                            sx={{ whiteSpace: 'pre-wrap', lineHeight: 1.6, color: 'text.primary' }}
                          >
                            {msg.content}
                          </Typography>
                        </Box>
                      </Box>
                    </Box>
                  )
                )}
                {/* Thinking indicator */}
                {aiLoading && (
                  <Box sx={{ display: 'flex', justifyContent: 'flex-start', alignItems: 'flex-start', gap: 1 }}>
                    <Avatar sx={{ width: 28, height: 28, bgcolor: '#F7941D', flexShrink: 0 }}>
                      <AutoAwesomeIcon sx={{ fontSize: 16, color: '#fff' }} />
                    </Avatar>
                    <Box
                      sx={{
                        bgcolor: 'action.hover',
                        px: 2,
                        py: 1,
                        borderRadius: '16px 16px 16px 4px',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 1,
                      }}
                    >
                      <CircularProgress size={14} sx={{ color: '#F7941D' }} />
                      <Typography variant="body2" color="text.secondary">
                        {t('search.thinking', 'Thinking...')}
                      </Typography>
                    </Box>
                  </Box>
                )}
                <div ref={chatEndRef} />
              </Box>
            )}

            {/* Search Results */}
            {(loading || semanticLoading) && !hasResults && !hasChat && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, p: 2.5 }}>
                <CircularProgress size={20} sx={semanticLoading ? { color: '#F7941D' } : undefined} />
                <Typography variant="body2" color="text.secondary">
                  {semanticLoading ? t('search.ai_searching', 'AI is searching...') : t('search.searching', 'Searching...')}
                </Typography>
              </Box>
            )}
            {!loading && !semanticLoading && results && !hasResults && !hasChat && (
              <Box sx={{ p: 2.5 }}>
                <Typography variant="body2" color="text.secondary">
                  {t('search.no_results', 'No results found')} &ldquo;{query}&rdquo;
                </Typography>
              </Box>
            )}
            {hasResults && (
              <List disablePadding>
                {/* AI Search Results indicator */}
                {isSemanticResult && (
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, px: 2, pt: 1.5, pb: 0.5 }}>
                    <AutoAwesomeIcon sx={{ fontSize: 16, color: '#F7941D' }} />
                    <Typography variant="caption" sx={{ fontWeight: 700, color: '#F7941D', textTransform: 'uppercase', letterSpacing: 0.8 }}>
                      {t('search.ai_results', 'AI Search Results')}
                    </Typography>
                  </Box>
                )}
                {navigationItems
                  .filter((nav) => results[nav.objectType])
                  .map((nav, idx) => {
                    const Icon = nav.icon;
                    const items = results[nav.objectType];
                    return (
                      <Box key={nav.objectType}>
                        {idx > 0 && <Box sx={{ borderTop: 1, borderColor: 'divider' }} />}
                        <ListSubheader
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1,
                            py: 1.5,
                            lineHeight: 'normal',
                            bgcolor: 'background.paper',
                          }}
                        >
                          <Icon fontSize="small" sx={{ color: 'primary.main' }} />
                          <Typography variant="body2" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.8, color: 'text.primary' }}>
                            {nav.label}
                          </Typography>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: 'primary.main' }}>
                            {items.length}
                          </Typography>
                        </ListSubheader>
                        {items.map((item) => (
                          <ListItemButton
                            key={item.id}
                            onClick={() => handleSelect(item.slug, item.id)}
                            sx={{ pl: 5.5, py: 1.2 }}
                          >
                            <ListItemText
                              primary={item.displayName || 'Untitled'}
                              secondary={item.reason || null}
                              primaryTypographyProps={{ variant: 'body1', noWrap: true }}
                              secondaryTypographyProps={{ variant: 'caption', color: 'text.secondary', noWrap: true }}
                            />
                            {item.autoNumber && (
                              <Chip
                                label={`#${item.autoNumber}`}
                                size="small"
                                variant="outlined"
                                color="primary"
                                sx={{ ml: 1.5, height: 22, fontSize: '0.75rem' }}
                              />
                            )}
                          </ListItemButton>
                        ))}
                      </Box>
                    );
                  })}
              </List>
            )}
          </Paper>
        )}

        {/* Search input */}
        {!isMobile && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <AutoAwesomeIcon fontSize="small" sx={{ color: 'info.main' }} />
            <Typography variant="body2" sx={{ fontWeight: 600, whiteSpace: 'nowrap' }}>
              {t('search.ask', 'Ask')}
            </Typography>
          </Box>
        )}
        <TextField
          inputRef={inputRef}
          fullWidth
          size="small"
          placeholder={isMobile ? t('search.placeholder_short', 'Search or ask AI...') : t('search.placeholder', 'Ask AI or search across all records (Ctrl+K)')}
          variant="outlined"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          sx={{
            '& .MuiOutlinedInput-root': {
              fontSize: '0.85rem',
              '& fieldset': { border: 'none' },
            },
          }}
        />
        {(loading || aiLoading || semanticLoading) && <CircularProgress size={18} />}
      </Paper>
    </ClickAwayListener>
  );
}
