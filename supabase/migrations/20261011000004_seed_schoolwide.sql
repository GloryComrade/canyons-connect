-- Canyons Connect — school-wide content seed
-- User data (schedule, grades, assignments) comes from integration syncs; this
-- seeds only the shared content every student sees. Safe to edit for your school.

insert into public.clubs (name, category, description, meeting_info, member_count, advisor) values
  ('Robotics Team', 'STEM', 'Design, build, and compete with the Hillcrest robotics team.', 'Tue & Thu · 3:30 PM · Rm 212', 28, 'Dr. Reyes'),
  ('Ultimate Frisbee', 'Sports', 'Casual and competitive ultimate for all skill levels.', 'Mon & Wed · 4:00 PM · Lower field', 19, 'Coach Lee'),
  ('Orange Club', 'Service', 'Service projects and community volunteering across the valley.', 'Fri · 12:45 PM · Rm 140', 34, 'Ms. Okafor'),
  ('Drama Club', 'Arts', 'Stagecraft, acting, and the fall & spring productions.', 'Mon–Thu · 3:30 PM · Auditorium', 41, 'Mr. Hart'),
  ('Student Council', 'Leadership', 'Plan school events, spirit weeks, and represent the student body.', 'Wed · 3:30 PM · Rm 120', 22, 'Ms. Okafor'),
  ('Science Olympiad', 'STEM', 'Compete in science and engineering events across 23 disciplines.', 'Thu · 3:30 PM · Rm 214', 17, 'Dr. Reyes'),
  ('Model UN', 'Academic', 'Debate global issues and travel to conferences.', 'Tue · 3:30 PM · Rm 231', 15, 'Mr. Dawson'),
  ('Key Club', 'Service', 'The largest student-led service organization.', 'Fri · 3:30 PM · Rm 108', 30, 'Ms. Carter');

insert into public.news_items (title, kind, body, category, author, duration_seconds, published_at) values
  ('Inside Canyons'' new robotics lab', 'video', 'A look inside the newly opened robotics and engineering lab at Hillcrest.', 'STEM', 'Student Media', 184, now() - interval '5 hours'),
  ('Block schedule, one year in: what''s working', 'article', 'Students and teachers reflect on the first full year of block scheduling.', 'School', 'J. Alvarez', null, now() - interval '1 day'),
  ('Cedar Canyon edges Alta 21–17 in season opener', 'article', 'A late-game stop sealed the win for the Huskies.', 'Sports', 'Husky Sports Desk', null, now() - interval '2 days'),
  ('What Canyons students actually think of the IB Diploma', 'video', null, 'Academics', 'Student Media', 263, now() - interval '3 days'),
  ('Meet the seniors running "Our Town" this fall', 'article', null, 'Arts', 'A. Chen', null, now() - interval '4 days');

insert into public.newsletters (title, teaser, body, published_at) values
  ('The Husky Weekly — Week of Oct 6', 'Homecoming spirit week, new robotics lab opens, and fall sports standings.', 'Welcome to this week''s edition of The Husky Weekly…', now() - interval '2 days'),
  ('Counseling Center: November Course Registration', 'Key dates and steps for registering for spring semester courses.', 'Registration opens November 1…', now() - interval '9 days');

insert into public.photo_events (title, subtitle, cover_url, photo_count, contributor_count, is_live, starts_at) values
  ('Friday Night Lights vs. Corner Canyon', 'Varsity football · Home', null, 128, 42, true, now()),
  ('Homecoming 2026', 'Dance & spirit week', null, 86, 30, false, now() - interval '7 days'),
  ('Robotics Regionals', 'Competition day', null, 54, 12, false, now() - interval '14 days'),
  ('Fall Play — Our Town', 'Opening night', null, 33, 9, false, now() - interval '21 days');

-- School-wide calendar (user_id null → visible to everyone via RLS)
insert into public.events (user_id, source, title, starts_at, type) values
  (null, 'school_site', 'Early-out day', (now()::date + 1) + time '13:00', 'early_out'),
  (null, 'school_site', 'PSAT testing', (now()::date + 3) + time '08:00', 'test'),
  (null, 'school_site', 'No school — Teacher PD', (now()::date + 7), 'holiday');
