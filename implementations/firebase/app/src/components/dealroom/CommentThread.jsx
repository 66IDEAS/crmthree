import { useState, useEffect, useMemo } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import SendIcon from '@mui/icons-material/Send';
import { useAuth } from '../../contexts/AuthContext';
import { useList, useMutation } from '../../hooks/useDataService';
import DataService from '../../services/DataService';
import { t } from '../../services/TranslationService';
import { timeAgo } from '../../utils/timeUtils';

export default function CommentThread({ parentType, parentId }) {
  const { userProfile } = useAuth();
  const [newComment, setNewComment] = useState('');
  const [authors, setAuthors] = useState({});

  const filterOpts = useMemo(() => ({
    filters: [
      { field: 'parent_type', op: '==', value: parentType },
      { field: 'parent_id', op: '==', value: parentId },
    ],
    pageSize: 200,
  }), [parentType, parentId]);

  const { data: comments, loading, refetch } = useList('Comment', filterOpts);
  const { create, loading: posting } = useMutation('Comment');

  const sorted = useMemo(
    () => [...(comments || [])].sort((a, b) => (a.created_at || '').localeCompare(b.created_at || '')),
    [comments]
  );

  // Resolve author profiles
  useEffect(() => {
    if (!comments?.length) return;
    const uniqueIds = [...new Set(comments.map((c) => c.author_id).filter(Boolean))];
    const missing = uniqueIds.filter((id) => !authors[id]);
    if (missing.length === 0) return;

    let cancelled = false;
    Promise.all(missing.map((id) => DataService.getById('UserProfile', id).catch(() => null)))
      .then((profiles) => {
        if (cancelled) return;
        const newAuthors = { ...authors };
        missing.forEach((id, i) => {
          if (profiles[i]) newAuthors[id] = profiles[i];
        });
        setAuthors(newAuthors);
      });
    return () => { cancelled = true; };
  }, [comments]); // eslint-disable-line react-hooks/exhaustive-deps

  const handlePost = async () => {
    if (!newComment.trim()) return;
    await create({
      parent_type: parentType,
      parent_id: parentId,
      content: newComment.trim(),
      author_id: userProfile?.id,
    });
    setNewComment('');
    refetch();
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
      handlePost();
    }
  };

  const getInitials = (profile) => {
    if (!profile) return '?';
    return [profile.first_name?.[0], profile.last_name?.[0]].filter(Boolean).join('').toUpperCase() || '?';
  };

  const getAuthorName = (authorId) => {
    const profile = authors[authorId];
    if (!profile) return t('ui.unknown', 'Unknown');
    return [profile.first_name, profile.last_name].filter(Boolean).join(' ') || profile.email || t('ui.unknown', 'Unknown');
  };

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {t('section.discussion', 'Discussion')}
        </Typography>
        {!loading && (
          <Chip label={sorted.length} size="small" variant="outlined" />
        )}
      </Box>

      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </Box>
      )}

      {!loading && sorted.length === 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: 'center' }}>
          {t('dealroom.no_comments', 'No comments yet. Start the discussion.')}
        </Typography>
      )}

      {/* Comment list */}
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5, mb: 2 }}>
        {sorted.map((comment) => (
          <Box key={comment.id} sx={{ display: 'flex', gap: 1.5 }}>
            <Avatar src={authors[comment.author_id]?.avatar_url || undefined} sx={{ width: 28, height: 28, fontSize: '0.75rem', bgcolor: 'primary.main', flexShrink: 0 }}>
              {getInitials(authors[comment.author_id])}
            </Avatar>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1 }}>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {getAuthorName(comment.author_id)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {timeAgo(comment.created_at)}
                </Typography>
              </Box>
              <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap', mt: 0.25 }}>
                {comment.content}
              </Typography>
            </Box>
          </Box>
        ))}
      </Box>

      {/* New comment input */}
      <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-end' }}>
        <TextField
          fullWidth
          multiline
          minRows={2}
          maxRows={4}
          size="small"
          placeholder={t('dealroom.write_comment', 'Write a comment...')}
          value={newComment}
          onChange={(e) => setNewComment(e.target.value)}
          onKeyDown={handleKeyDown}
        />
        <Button
          variant="contained"
          size="small"
          onClick={handlePost}
          disabled={posting || !newComment.trim()}
          sx={{ minWidth: 'auto', px: 1.5 }}
        >
          <SendIcon fontSize="small" />
        </Button>
      </Box>
    </Paper>
  );
}
