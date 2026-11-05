
CREATE DATABASE TEAMLY;
GO

USE TEAMLY;
GO

-- 1. USERS
-- Stores all accounts: clients, providers, and admins.
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(254) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    display_name NVARCHAR(120) NOT NULL,
    role NVARCHAR(20) NOT NULL,       -- client, provider, or admin
    phone NVARCHAR(30),
    status NVARCHAR(20),              -- active, pending, or suspended
    created_at DATETIME DEFAULT GETDATE()
);
GO

-- 2. PROVIDER PROFILES
-- Stores extra information about users who are service providers.
CREATE TABLE provider_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    provider_type NVARCHAR(20) NOT NULL,  -- individual or company
    business_name NVARCHAR(160),
    representative_name NVARCHAR(120) NOT NULL,
    tagline NVARCHAR(180),
    description NVARCHAR(2000),
    starting_price DECIMAL(12,2),
    currency NVARCHAR(10) DEFAULT 'JOD',
    profile_photo_url NVARCHAR(2048),
    status NVARCHAR(20),                  -- active, pending, or inactive
    verified_at DATETIME,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO

-- 3. SERVICES
-- Stores the services offered by each provider.
CREATE TABLE services (
    id INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT NOT NULL,
    name NVARCHAR(140) NOT NULL,
    category NVARCHAR(40) NOT NULL,
    description NVARCHAR(2000),
    base_price DECIMAL(12,2) NOT NULL,
    currency NVARCHAR(10) DEFAULT 'JOD',
    status NVARCHAR(20),              -- draft, published, or paused
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 4. PROJECTS
-- Stores projects created by clients.
CREATE TABLE projects (
    id INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL,
    provider_id INT,
    title NVARCHAR(160) NOT NULL,
    project_type NVARCHAR(60),
    description NVARCHAR(4000),
    planning_summary NVARCHAR(2000),
    event_date DATE,
    location NVARCHAR(200),
    budget DECIMAL(12,2),
    team_status NVARCHAR(30),       -- not_started, planning, or organized
    status NVARCHAR(20),            -- active, pending, completed, or cancelled
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,

    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 5. EVENTS
-- Stores events related to a client and, optionally, a project.
CREATE TABLE events (
    id INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL,
    project_id INT,
    title NVARCHAR(140) NOT NULL,
    event_type NVARCHAR(40) NOT NULL,
    event_date DATE,
    guest_count INT,
    status NVARCHAR(20),            -- planning, confirmed, completed, or cancelled
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);
GO

-- 6. PROJECT REQUESTS
-- Stores requests sent from a client project to a provider.
CREATE TABLE project_requests (
    id INT IDENTITY(1,1) PRIMARY KEY,
    project_id INT NOT NULL,
    provider_id INT NOT NULL,
    service_id INT NOT NULL,
    status NVARCHAR(20),            -- new, pending, accepted, rejected, or expired
    created_at DATETIME DEFAULT GETDATE(),
    responded_at DATETIME,

    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);
GO

-- 7. BOOKINGS
-- Stores bookings made by clients.
CREATE TABLE bookings (
    id INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL,
    service_id INT NOT NULL,
    event_id INT,
    project_id INT,
    project_request_id INT,
    requested_date DATE,
    agreed_price DECIMAL(12,2),
    status NVARCHAR(20),            -- pending, accepted, declined, cancelled, or completed
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (service_id) REFERENCES services(id),
    FOREIGN KEY (event_id) REFERENCES events(id),
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (project_request_id) REFERENCES project_requests(id)
);
GO

-- 8. BOOKING SERVICES
-- Connects bookings with services and stores the agreed price for each service.
-- The two columns together form the primary key.
CREATE TABLE booking_services (
    booking_id INT NOT NULL,
    service_id INT NOT NULL,
    agreed_price DECIMAL(12,2) NOT NULL,

    PRIMARY KEY (booking_id, service_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);
GO

-- 9. PAYMENTS
-- Stores payments made for bookings or projects.
CREATE TABLE payments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    booking_id INT,
    project_id INT,
    payer_id INT,
    amount DECIMAL(12,2) NOT NULL,
    commission_amount DECIMAL(12,2) DEFAULT 0,
    currency NVARCHAR(10) DEFAULT 'JOD',
    method NVARCHAR(30),
    status NVARCHAR(20),            -- pending, successful, failed, or refunded
    provider_reference NVARCHAR(120),
    paid_at DATETIME,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (payer_id) REFERENCES users(id)
);
GO

-- 10. REVIEWS
-- Stores client reviews for completed bookings.
CREATE TABLE reviews (
    id INT IDENTITY(1,1) PRIMARY KEY,
    booking_id INT NOT NULL,
    client_id INT NOT NULL,
    rating INT NOT NULL,            -- rating from 1 to 5
    comment NVARCHAR(1500),
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (client_id) REFERENCES users(id)
);
GO

-- 11. MESSAGES
-- Stores messages sent by users inside a booking conversation.
CREATE TABLE messages (
    id INT IDENTITY(1,1) PRIMARY KEY,
    booking_id INT NOT NULL,
    sender_id INT NOT NULL,
    body NVARCHAR(4000) NOT NULL,
    sent_at DATETIME DEFAULT GETDATE(),
    read_at DATETIME,

    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (sender_id) REFERENCES users(id)
);
GO

-- 12. SUBSCRIPTIONS
-- Stores provider subscription information.
CREATE TABLE subscriptions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT NOT NULL,
    plan_name NVARCHAR(40) NOT NULL,    -- free, professional, or business
    price DECIMAL(10,2) NOT NULL,
    currency NVARCHAR(10) DEFAULT 'JOD',
    billing_period NVARCHAR(20) NOT NULL, -- for example: month
    status NVARCHAR(20),                -- active, expired, cancelled, or pending
    starts_at DATETIME NOT NULL,
    renewal_at DATETIME,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 13. AI CONVERSATIONS
-- Stores AI chat conversations started by users.
CREATE TABLE ai_conversations (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    project_id INT,
    title NVARCHAR(140),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);
GO

-- 14. AI CHAT MESSAGES
-- Stores each message inside an AI conversation.
CREATE TABLE ai_chat_messages (
    id INT IDENTITY(1,1) PRIMARY KEY,
    conversation_id INT NOT NULL,
    sequence_no INT NOT NULL,
    sender NVARCHAR(10) NOT NULL,       -- user or ai
    body NVARCHAR(MAX) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    edited_at DATETIME,

    FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id)
);
GO

-- 15. PROVIDER PORTFOLIO ITEMS
-- Stores provider portfolio images, videos, and links.
CREATE TABLE provider_portfolio_items (
    id INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT NOT NULL,
    item_type NVARCHAR(12) NOT NULL,    -- image, video, or link
    title NVARCHAR(160) NOT NULL,
    media_url NVARCHAR(2048) NOT NULL,
    mime_type NVARCHAR(100),
    sort_order INT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 16. PROVIDER EXPERIENCES
-- Stores provider work experience.
CREATE TABLE provider_experiences (
    id INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT NOT NULL,
    organization NVARCHAR(120) NOT NULL,
    role NVARCHAR(120),
    period NVARCHAR(80),
    description NVARCHAR(500),
    sort_order INT DEFAULT 0,

    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 17. PROVIDER SERVICE AREAS
-- Stores the locations where each provider offers services.
CREATE TABLE provider_service_areas (
    provider_id INT NOT NULL,
    location NVARCHAR(100) NOT NULL,

    PRIMARY KEY (provider_id, location),
    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 18. SAVED PROVIDERS
-- Stores providers saved by users.
CREATE TABLE saved_providers (
    user_id INT NOT NULL,
    provider_id INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (user_id, provider_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 19. ADMIN PROJECT FOLLOWS
-- Stores projects followed by admin users.
CREATE TABLE admin_project_follows (
    admin_user_id INT NOT NULL,
    project_id INT NOT NULL,
    followed_at DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (admin_user_id, project_id),
    FOREIGN KEY (admin_user_id) REFERENCES users(id),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);
GO

-- 20. PROVIDER FEEDBACK
-- Stores feedback submitted by providers.
CREATE TABLE provider_feedback (
    id INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT NOT NULL,
    choice NVARCHAR(20) NOT NULL,       -- going_well or concern
    submitted_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (provider_id) REFERENCES provider_profiles(id)
);
GO

-- 21. ADMIN ACTIVITY EVENTS
-- Stores activities that appear in the admin activity section.
CREATE TABLE admin_activity_events (
    id INT IDENTITY(1,1) PRIMARY KEY,
    external_key NVARCHAR(120),
    actor_user_id INT,
    provider_feedback_id INT,
    kind NVARCHAR(20) NOT NULL,         -- registration, feedback, zoom, or activity
    title NVARCHAR(160) NOT NULL,
    actor_label NVARCHAR(160) NOT NULL,
    detail NVARCHAR(1000) NOT NULL,
    occurred_at DATETIME,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (actor_user_id) REFERENCES users(id),
    FOREIGN KEY (provider_feedback_id) REFERENCES provider_feedback(id)
);
GO

-- 22. ADMIN ACTIVITY READS
-- Stores which admin users have read each activity.
CREATE TABLE admin_activity_reads (
    admin_user_id INT NOT NULL,
    activity_event_id INT NOT NULL,
    read_at DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (admin_user_id, activity_event_id),
    FOREIGN KEY (admin_user_id) REFERENCES users(id),
    FOREIGN KEY (activity_event_id) REFERENCES admin_activity_events(id)
);
GO

-- 23. ADMIN AUDIT LOG
-- Stores changes made by admin users to client or provider accounts.
CREATE TABLE admin_audit_log (
    id INT IDENTITY(1,1) PRIMARY KEY,
    admin_user_id INT NOT NULL,
    subject_user_id INT NOT NULL,
    target_type NVARCHAR(20) NOT NULL,  -- client or provider
    action NVARCHAR(20) NOT NULL,       -- create or update
    field_name NVARCHAR(100),
    old_value NVARCHAR(MAX),
    new_value NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (admin_user_id) REFERENCES users(id),
    FOREIGN KEY (subject_user_id) REFERENCES users(id)
);
GO

-- 24. NOTIFICATIONS
-- Stores notifications sent to users.
CREATE TABLE notifications (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    kind NVARCHAR(40) NOT NULL,
    title NVARCHAR(160) NOT NULL,
    body NVARCHAR(1000) NOT NULL,
    read_at DATETIME,
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO

USE TEAMLY;
GO

-- TEAMLY fictional sample data; inserts follow foreign-key order.

-- Users: client, provider, and admin accounts.
SET IDENTITY_INSERT users ON;

INSERT INTO users (id, email, password_hash, display_name, role, phone, status, created_at)
VALUES (1, N'alia.client@example.test', N'demo-hash-client', N'Alia Nasser', N'client', NULL, N'active', N'2026-10-01T09:00:00');

INSERT INTO users (id, email, password_hash, display_name, role, phone, status, created_at)
VALUES (2, N'sami.provider@example.test', N'demo-hash-provider', N'Sami Haddad', N'provider', N'+962790000002', N'active', N'2026-10-02T10:00:00');

INSERT INTO users (id, email, password_hash, display_name, role, phone, status, created_at)
VALUES (3, N'noor.client@example.test', N'demo-hash-client-2', N'Noor Saleh', N'client', NULL, N'active', N'2026-10-03T11:00:00');

INSERT INTO users (id, email, password_hash, display_name, role, phone, status, created_at)
VALUES (4, N'sara.admin@example.test', N'demo-hash-admin', N'Sara Admin', N'admin', NULL, N'active', N'2026-10-01T08:00:00');

-- Finish inserting the example IDs for users.
SET IDENTITY_INSERT users OFF;

-- Provider Profiles: extra information about provider accounts.
SET IDENTITY_INSERT provider_profiles ON;

INSERT INTO provider_profiles (id, user_id, provider_type, business_name, representative_name, tagline, description, starting_price, currency, profile_photo_url, status, verified_at, created_at)
VALUES (1, 2, N'company', N'Sami Events Studio', N'Sami Haddad', N'Thoughtful event services', N'Event services for small and large celebrations.', 180, N'JOD', NULL, N'active', N'2026-10-04T12:00:00', N'2026-10-04T12:00:00');

-- Finish inserting the example IDs for provider_profiles.
SET IDENTITY_INSERT provider_profiles OFF;

-- Services: services offered by providers.
SET IDENTITY_INSERT services ON;

INSERT INTO services (id, provider_id, name, category, description, base_price, currency, status, created_at)
VALUES (1, 1, N'Event Photography', N'photography', N'Full-day event photography package.', 650, N'JOD', N'published', N'2026-10-05T08:00:00');

INSERT INTO services (id, provider_id, name, category, description, base_price, currency, status, created_at)
VALUES (2, 1, N'Celebration Catering', N'catering', N'Buffet service for private events.', 180, N'JOD', N'published', N'2026-10-05T08:30:00');

-- Finish inserting the example IDs for services.
SET IDENTITY_INSERT services OFF;

-- Projects: projects created by clients.
SET IDENTITY_INSERT projects ON;

INSERT INTO projects (id, client_id, provider_id, title, project_type, description, planning_summary, event_date, location, budget, team_status, status, created_at, updated_at)
VALUES (1, 1, 1, N'Alia''s celebration', N'Wedding', N'Plan photography and catering for a family celebration.', N'Photography booked; add-on catering selected.', N'2026-10-30', N'Amman', 1000, N'organized', N'completed', N'2026-10-06T09:00:00', N'2026-10-31T09:00:00');

INSERT INTO projects (id, client_id, provider_id, title, project_type, description, planning_summary, event_date, location, budget, team_status, status, created_at, updated_at)
VALUES (2, 3, NULL, N'Noor''s birthday', N'Birthday', N'Arrange catering for a birthday celebration.', N'Waiting for a provider response.', N'2026-12-12', N'Amman', 500, N'planning', N'active', N'2026-10-07T09:00:00', N'2026-10-09T10:00:00');

-- Finish inserting the example IDs for projects.
SET IDENTITY_INSERT projects OFF;

-- Events: events connected to clients and projects.
SET IDENTITY_INSERT events ON;

INSERT INTO events (id, client_id, project_id, title, event_type, event_date, guest_count, status, created_at)
VALUES (1, 1, 1, N'Alia''s celebration', N'Wedding', N'2026-10-30', 120, N'completed', N'2026-10-06T09:00:00');

INSERT INTO events (id, client_id, project_id, title, event_type, event_date, guest_count, status, created_at)
VALUES (2, 3, 2, N'Noor''s birthday', N'Birthday', N'2026-12-12', 35, N'planning', N'2026-10-07T09:00:00');

-- Finish inserting the example IDs for events.
SET IDENTITY_INSERT events OFF;

-- Project Requests: requests sent to providers.
SET IDENTITY_INSERT project_requests ON;

INSERT INTO project_requests (id, project_id, provider_id, service_id, status, created_at, responded_at)
VALUES (1, 1, 1, 1, N'accepted', N'2026-10-07T09:30:00', N'2026-10-08T10:00:00');

INSERT INTO project_requests (id, project_id, provider_id, service_id, status, created_at, responded_at)
VALUES (2, 2, 1, 2, N'new', N'2026-10-09T10:00:00', NULL);

-- Finish inserting the example IDs for project_requests.
SET IDENTITY_INSERT project_requests OFF;

-- Bookings: client bookings for services.
SET IDENTITY_INSERT bookings ON;

INSERT INTO bookings (id, client_id, service_id, event_id, project_id, project_request_id, requested_date, agreed_price, status, created_at)
VALUES (1, 1, 1, 1, 1, 1, N'2026-10-30', 650, N'completed', N'2026-10-08T10:00:00');

INSERT INTO bookings (id, client_id, service_id, event_id, project_id, project_request_id, requested_date, agreed_price, status, created_at)
VALUES (2, 3, 2, 2, 2, 2, N'2026-12-12', 180, N'pending', N'2026-10-09T10:00:00');

-- Finish inserting the example IDs for bookings.
SET IDENTITY_INSERT bookings OFF;

-- Booking Services: connects bookings with their selected services.
INSERT INTO booking_services (booking_id, service_id, agreed_price)
VALUES (1, 2, 180);

-- Payments: payment records and platform commission.
SET IDENTITY_INSERT payments ON;

INSERT INTO payments (id, booking_id, project_id, payer_id, amount, commission_amount, currency, method, status, provider_reference, paid_at, created_at)
VALUES (1, 1, 1, 1, 650, 97.5, N'JOD', N'Card', N'successful', N'PAY-DEMO-001', N'2026-10-10T11:00:00', N'2026-10-10T10:30:00');

INSERT INTO payments (id, booking_id, project_id, payer_id, amount, commission_amount, currency, method, status, provider_reference, paid_at, created_at)
VALUES (2, 2, 2, 3, 180, 0, N'JOD', N'Card', N'pending', NULL, NULL, N'2026-10-11T10:30:00');

-- Finish inserting the example IDs for payments.
SET IDENTITY_INSERT payments OFF;

-- Reviews: client ratings and comments.
SET IDENTITY_INSERT reviews ON;

INSERT INTO reviews (id, booking_id, client_id, rating, comment, created_at)
VALUES (1, 1, 1, 5, N'Wonderful service and clear communication.', N'2026-11-01T14:00:00');

-- Finish inserting the example IDs for reviews.
SET IDENTITY_INSERT reviews OFF;

-- Messages: messages exchanged in booking conversations.
SET IDENTITY_INSERT messages ON;

INSERT INTO messages (id, booking_id, sender_id, body, sent_at, read_at)
VALUES (1, 1, 1, N'Thank you for the gallery.', N'2026-10-31T09:00:00', N'2026-10-31T09:10:00');

INSERT INTO messages (id, booking_id, sender_id, body, sent_at, read_at)
VALUES (2, 1, 2, N'Glad you like the photos.', N'2026-10-31T09:15:00', NULL);

INSERT INTO messages (id, booking_id, sender_id, body, sent_at, read_at)
VALUES (3, 2, 3, N'Please confirm the menu options.', N'2026-10-12T12:00:00', NULL);

-- Finish inserting the example IDs for messages.
SET IDENTITY_INSERT messages OFF;

-- Subscriptions: provider subscription details.
SET IDENTITY_INSERT subscriptions ON;

INSERT INTO subscriptions (id, provider_id, plan_name, price, currency, billing_period, status, starts_at, renewal_at, created_at)
VALUES (1, 1, N'professional', 9.99, N'USD', N'month', N'active', N'2026-10-01T00:00:00', N'2026-11-01T00:00:00', N'2026-10-01T00:00:00');

-- Finish inserting the example IDs for subscriptions.
SET IDENTITY_INSERT subscriptions OFF;

-- AI Conversations: conversations started with the AI assistant.
SET IDENTITY_INSERT ai_conversations ON;

INSERT INTO ai_conversations (id, user_id, project_id, title, created_at, updated_at)
VALUES (1, 1, 1, N'Wedding photography and catering', N'2026-10-06T08:00:00', N'2026-10-06T08:10:00');

-- Finish inserting the example IDs for ai_conversations.
SET IDENTITY_INSERT ai_conversations OFF;

-- AI Chat Messages: messages inside AI conversations.
SET IDENTITY_INSERT ai_chat_messages ON;

INSERT INTO ai_chat_messages (id, conversation_id, sequence_no, sender, body, created_at, edited_at)
VALUES (1, 1, 1, N'ai', N'Tell me about the event you are planning.', N'2026-10-06T08:00:00', NULL);

INSERT INTO ai_chat_messages (id, conversation_id, sequence_no, sender, body, created_at, edited_at)
VALUES (2, 1, 2, N'user', N'I am planning a wedding in Amman and need photography.', N'2026-10-06T08:05:00', NULL);

INSERT INTO ai_chat_messages (id, conversation_id, sequence_no, sender, body, created_at, edited_at)
VALUES (3, 1, 3, N'ai', N'I added photography to your planning notes.', N'2026-10-06T08:05:10', NULL);

-- Finish inserting the example IDs for ai_chat_messages.
SET IDENTITY_INSERT ai_chat_messages OFF;

-- Provider Portfolio Items: provider images, videos, and links.
SET IDENTITY_INSERT provider_portfolio_items ON;

INSERT INTO provider_portfolio_items (id, provider_id, item_type, title, media_url, mime_type, sort_order, created_at)
VALUES (1, 1, N'image', N'Garden celebration', N'portfolio/provider-1/garden-celebration.webp', N'image/webp', 1, N'2026-10-05T09:00:00');

-- Finish inserting the example IDs for provider_portfolio_items.
SET IDENTITY_INSERT provider_portfolio_items OFF;

-- Provider Experiences: provider work experience.
SET IDENTITY_INSERT provider_experiences ON;

INSERT INTO provider_experiences (id, provider_id, organization, role, period, description, sort_order)
VALUES (1, 1, N'Sami Events Studio', N'Lead event provider', N'2021–present', N'Planning and delivering event services.', 1);

-- Finish inserting the example IDs for provider_experiences.
SET IDENTITY_INSERT provider_experiences OFF;

-- Provider Service Areas: locations where providers work.
INSERT INTO provider_service_areas (provider_id, location)
VALUES (1, N'Amman');

INSERT INTO provider_service_areas (provider_id, location)
VALUES (1, N'Zarqa');

-- Saved Providers: providers saved by users.
INSERT INTO saved_providers (user_id, provider_id, created_at)
VALUES (1, 1, N'2026-10-06T08:20:00');

-- Admin Project Follows: projects followed by admins.
INSERT INTO admin_project_follows (admin_user_id, project_id, followed_at)
VALUES (4, 1, N'2026-10-10T08:00:00');

-- Provider Feedback: feedback submitted by providers.
SET IDENTITY_INSERT provider_feedback ON;

INSERT INTO provider_feedback (id, provider_id, choice, submitted_at)
VALUES (1, 1, N'going_well', N'2026-10-12T12:00:00');

-- Finish inserting the example IDs for provider_feedback.
SET IDENTITY_INSERT provider_feedback OFF;

-- Admin Activity Events: activities shown to admins.
SET IDENTITY_INSERT admin_activity_events ON;

INSERT INTO admin_activity_events (id, external_key, actor_user_id, provider_feedback_id, kind, title, actor_label, detail, occurred_at, created_at)
VALUES (1, N'feedback-demo-1', 2, 1, N'feedback', N'Provider check-in', N'Sami Haddad', N'Everything is going well.', N'2026-10-12T12:00:00', N'2026-10-12T12:00:00');

INSERT INTO admin_activity_events (id, external_key, actor_user_id, provider_feedback_id, kind, title, actor_label, detail, occurred_at, created_at)
VALUES (2, N'signup-provider-demo-1', 2, NULL, N'registration', N'Provider registered', N'Sami Haddad', N'Provider account created for event services.', N'2026-10-04T12:00:00', N'2026-10-04T12:00:00');

-- Finish inserting the example IDs for admin_activity_events.
SET IDENTITY_INSERT admin_activity_events OFF;

-- Admin Activity Reads: activities already read by admins.
INSERT INTO admin_activity_reads (admin_user_id, activity_event_id, read_at)
VALUES (4, 2, N'2026-10-13T09:00:00');

-- Admin Audit Log: changes made by admins.
SET IDENTITY_INSERT admin_audit_log ON;

INSERT INTO admin_audit_log (id, admin_user_id, subject_user_id, target_type, action, field_name, old_value, new_value, created_at)
VALUES (1, 4, 2, N'provider', N'update', N'status', N'pending', N'active', N'2026-10-04T12:05:00');

-- Finish inserting the example IDs for admin_audit_log.
SET IDENTITY_INSERT admin_audit_log OFF;

-- Notifications: notifications sent to users.
SET IDENTITY_INSERT notifications ON;

INSERT INTO notifications (id, user_id, kind, title, body, read_at, created_at)
VALUES (1, 1, N'booking_completed', N'Booking complete', N'Your photography booking is complete.', N'2026-11-01T14:05:00', N'2026-10-31T10:00:00');

INSERT INTO notifications (id, user_id, kind, title, body, read_at, created_at)
VALUES (2, 2, N'booking_request', N'New booking request', N'A client requested Celebration Catering.', NULL, N'2026-10-09T10:01:00');

-- Finish inserting the example IDs for notifications.
SET IDENTITY_INSERT notifications OFF;
