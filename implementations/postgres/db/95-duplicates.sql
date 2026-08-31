-- Step 12. Duplicate detection (story 53) with trigram similarity, so "BMW Inc" and
-- "BMW Incorporated" match without exact spelling.
create extension if not exists pg_trgm;
