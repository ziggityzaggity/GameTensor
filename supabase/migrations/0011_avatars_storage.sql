-- Avatars storage bucket (Milestone 3). Security requirements from
-- docs/demo-completion-plan.md section 3.6: public read; users may write only
-- under a folder named their own uid; images only; 2 MB cap.

-- Public-read bucket. file_size_limit (2 MB) and allowed_mime_types are enforced
-- by Storage itself on every upload, so an oversized/non-image file is rejected
-- server-side even if a client skips the app-layer pre-check.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152, -- 2 MB
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public read: anyone can fetch an avatar by its public URL.
create policy avatars_public_read on storage.objects
  for select using (bucket_id = 'avatars');

-- Write access is scoped to the user's own top-level folder: the first path
-- segment must equal their uid, so a user can only create/replace/remove objects
-- under avatars/{their-uid}/... and never touch another user's avatar.
create policy avatars_insert_own on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy avatars_update_own on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy avatars_delete_own on storage.objects
  for delete using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
