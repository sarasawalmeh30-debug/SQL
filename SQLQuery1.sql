/* ============================================================
   TEAMLY database  (SQL Server)
   17 tables, 21 relations (foreign keys), sample data included.
   Run the whole file once on a fresh server (F5 in SSMS).
   IDs are typed by hand in the INSERT statements so the
   foreign keys are easy to follow.
   ============================================================ */

IF DB_ID('TEAMLY') IS NULL
    CREATE DATABASE TEAMLY;
GO

USE TEAMLY;
GO

/* ============================================================
   PART 1: CREATE TABLES
   ============================================================ */

-- 1) Everyone who can log in: clients, providers and admins
CREATE TABLE users (
    id            INT           NOT NULL PRIMARY KEY,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(150) NOT NULL UNIQUE,
    phone         NVARCHAR(20)  NULL,
    password_hash NVARCHAR(255) NOT NULL,
    role          NVARCHAR(10)  NOT NULL CHECK (role IN ('client', 'provider', 'admin')),
    status        NVARCHAR(10)  NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending', 'inactive')),
    created_at    DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 2) Extra data for users whose role is provider (one profile per user)
CREATE TABLE providers (
    id                  INT            NOT NULL PRIMARY KEY,
    user_id             INT            NOT NULL UNIQUE REFERENCES users(id),
    provider_type       NVARCHAR(10)   NOT NULL CHECK (provider_type IN ('individual', 'company')),
    company_name        NVARCHAR(100)  NULL,
    representative_name NVARCHAR(100)  NULL,
    business_email      NVARCHAR(150)  NULL,
    tagline             NVARCHAR(150)  NULL,
    location            NVARCHAR(100)  NOT NULL,
    description         NVARCHAR(1000) NULL,
    starting_price      DECIMAL(10,2)  NOT NULL,
    pricing_unit        NVARCHAR(20)   NOT NULL,   -- the price is for: hour / day / event
    pricing_quantity    INT            NOT NULL DEFAULT 1   -- how many units the price covers
);

-- 3) Kinds of work (Photography, Decoration, ...)
CREATE TABLE services (
    id   INT          NOT NULL PRIMARY KEY,
    name NVARCHAR(50) NOT NULL UNIQUE
);

-- 4) Links providers and services (many-to-many)
CREATE TABLE provider_services (
    provider_id INT NOT NULL REFERENCES providers(id),
    service_id  INT NOT NULL REFERENCES services(id),
    is_main     BIT NOT NULL DEFAULT 0,            -- 1 = main service, 0 = additional service
    PRIMARY KEY (provider_id, service_id)
);

-- 5) Photos and videos a provider shows on the profile
CREATE TABLE portfolio_items (
    id          INT           NOT NULL PRIMARY KEY,
    provider_id INT           NOT NULL REFERENCES providers(id),
    media_type  NVARCHAR(10)  NOT NULL CHECK (media_type IN ('photo', 'video')),
    file_url    NVARCHAR(300) NOT NULL
);

-- 6) Employees of a company provider
CREATE TABLE company_employees (
    id          INT           NOT NULL PRIMARY KEY,
    provider_id INT           NOT NULL REFERENCES providers(id),
    name        NVARCHAR(100) NOT NULL,
    specialty   NVARCHAR(100) NULL
);

-- 7) An event a client is planning
CREATE TABLE projects (
    id         INT           NOT NULL PRIMARY KEY,
    client_id  INT           NOT NULL REFERENCES users(id),
    name       NVARCHAR(100) NOT NULL,
    event_type NVARCHAR(30)  NOT NULL,
    location   NVARCHAR(100) NOT NULL,
    event_date DATE          NULL,
    budget     DECIMAL(10,2) NOT NULL,
    status     NVARCHAR(10)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled'))
);

-- 8) A project asking one provider for one service
CREATE TABLE requests (
    id          INT            NOT NULL PRIMARY KEY,
    project_id  INT            NOT NULL REFERENCES projects(id),
    provider_id INT            NOT NULL REFERENCES providers(id),
    service_id  INT            NOT NULL REFERENCES services(id),
    description NVARCHAR(1000) NULL,
    event_date  DATE           NULL,
    start_time  TIME           NULL,
    end_time    TIME           NULL,
    status      NVARCHAR(10)   NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'pending', 'accepted', 'rejected', 'expired')),
    deadline    DATE           NULL,
    created_at  DATETIME2      NOT NULL DEFAULT SYSDATETIME()
);

-- 9) The rating a client gives after a request is done (one review per request)
CREATE TABLE reviews (
    id         INT           NOT NULL PRIMARY KEY,
    request_id INT           NOT NULL UNIQUE REFERENCES requests(id),
    rating     TINYINT       NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    NVARCHAR(500) NULL,
    created_at DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 10) Plans: Free, Professional, Business (prices differ for individual and company)
CREATE TABLE subscription_plans (
    id            INT          NOT NULL PRIMARY KEY,
    name          NVARCHAR(30) NOT NULL,
    provider_type NVARCHAR(10) NOT NULL CHECK (provider_type IN ('individual', 'company')),
    price         DECIMAL(6,2) NOT NULL,           -- price per month in USD
    UNIQUE (name, provider_type)
);

-- 11) The plan a provider pays for
CREATE TABLE subscriptions (
    id           INT          NOT NULL PRIMARY KEY,
    provider_id  INT          NOT NULL REFERENCES providers(id),
    plan_id      INT          NOT NULL REFERENCES subscription_plans(id),
    status       NVARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'expired', 'cancelled', 'pending')),
    start_date   DATE         NOT NULL,
    renewal_date DATE         NULL
);

-- 12) A payment for a project (commission = TEAMLY share)
CREATE TABLE transactions (
    id         INT           NOT NULL PRIMARY KEY,
    project_id INT           NOT NULL REFERENCES projects(id),
    payer_id   INT           NOT NULL REFERENCES users(id),
    amount     DECIMAL(10,2) NOT NULL,
    commission DECIMAL(10,2) NOT NULL DEFAULT 0,
    method     NVARCHAR(20)  NOT NULL,             -- never store card number or CVV here
    status     NVARCHAR(10)  NOT NULL DEFAULT 'pending' CHECK (status IN ('successful', 'pending', 'failed', 'refunded')),
    created_at DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 13) Chat messages between a client and a provider
CREATE TABLE messages (
    id          INT           NOT NULL PRIMARY KEY,
    project_id  INT           NOT NULL REFERENCES projects(id),
    sender_id   INT           NOT NULL REFERENCES users(id),
    receiver_id INT           NOT NULL REFERENCES users(id),
    body        NVARCHAR(250) NOT NULL,
    sent_at     DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 14) Alerts shown to a user
CREATE TABLE notifications (
    id         INT           NOT NULL PRIMARY KEY,
    user_id    INT           NOT NULL REFERENCES users(id),
    title      NVARCHAR(100) NOT NULL,
    is_read    BIT           NOT NULL DEFAULT 0,
    created_at DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 15) Messages sent from the Need Help page
CREATE TABLE support_tickets (
    id            INT            NOT NULL PRIMARY KEY,
    user_id       INT            NULL REFERENCES users(id),   -- empty if the person was not logged in
    contact_email NVARCHAR(150)  NOT NULL,
    issue_type    NVARCHAR(30)   NOT NULL CHECK (issue_type IN ('Payment Issue', 'Provider Issue', 'Project Issue',
                                  'Communication Issue', 'Booking or Scheduling', 'Technical Issue', 'Others')),
    subject       NVARCHAR(100)  NULL,
    message       NVARCHAR(1000) NOT NULL,
    status        NVARCHAR(12)   NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'closed')),
    created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME()
);

-- 16) AI chat conversations (history list in the AI chat page)
CREATE TABLE ai_conversations (
    id         INT           NOT NULL PRIMARY KEY,
    user_id    INT           NOT NULL REFERENCES users(id),
    title      NVARCHAR(100) NOT NULL,
    created_at DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-- 17) Messages inside an AI conversation
CREATE TABLE ai_messages (
    id              INT            NOT NULL PRIMARY KEY,
    conversation_id INT            NOT NULL REFERENCES ai_conversations(id),
    sender          NVARCHAR(4)    NOT NULL CHECK (sender IN ('user', 'ai')),
    body            NVARCHAR(1000) NOT NULL,
    sent_at         DATETIME2      NOT NULL DEFAULT SYSDATETIME()
);
GO

/* ============================================================
   PART 2: INSERT DATA
   (keep this order: parent tables first, child tables after)
   ============================================================ */

-- users: 1 admin, 10 clients (2-11), 12 providers (12-23)
INSERT INTO users (id, full_name, email, phone, password_hash, role, status, created_at) VALUES
(1,  'TEAMLY Admin',   'admin@teamly.example.com',        NULL,         'hashed_password_1',  'admin',    'active',   '2026-09-01 09:00:00'),
(2,  'Sara Omar',      'sara.omar@example.com',           NULL,         'hashed_password_2',  'client',   'active',   '2026-09-10 10:15:00'),
(3,  'Lina Haddad',    'lina.haddad@example.com',         NULL,         'hashed_password_3',  'client',   'active',   '2026-09-12 14:20:00'),
(4,  'Omar Nasser',    'omar.nasser@example.com',         NULL,         'hashed_password_4',  'client',   'active',   '2026-09-15 11:05:00'),
(5,  'Rania Saleh',    'rania.saleh@example.com',         NULL,         'hashed_password_5',  'client',   'active',   '2026-09-18 16:40:00'),
(6,  'Yazan Farouk',   'yazan.farouk@example.com',        NULL,         'hashed_password_6',  'client',   'active',   '2026-09-22 09:30:00'),
(7,  'Dana Mansour',   'dana.mansour@example.com',        NULL,         'hashed_password_7',  'client',   'active',   '2026-09-25 13:10:00'),
(8,  'Khaled Aziz',    'khaled.aziz@example.com',         NULL,         'hashed_password_8',  'client',   'active',   '2026-10-01 18:00:00'),
(9,  'Huda Barakat',   'huda.barakat@example.com',        NULL,         'hashed_password_9',  'client',   'active',   '2026-10-03 12:45:00'),
(10, 'Tariq Jaber',    'tariq.jaber@example.com',         NULL,         'hashed_password_10', 'client',   'active',   '2026-10-06 15:25:00'),
(11, 'Maya Qasem',     'maya.qasem@example.com',          NULL,         'hashed_password_11', 'client',   'active',   '2026-10-09 10:00:00'),
(12, 'Ahmad Khaled',   'ahmad.khaled@example.com',        '0791000012', 'hashed_password_12', 'provider', 'active',   '2026-09-02 08:30:00'),
(13, 'Rami Odeh',      'rami.odeh@example.com',           '0791000013', 'hashed_password_13', 'provider', 'active',   '2026-09-03 09:10:00'),
(14, 'Salma Yousef',   'salma.yousef@example.com',        '0791000014', 'hashed_password_14', 'provider', 'active',   '2026-09-05 10:20:00'),
(15, 'Jad Mansour',    'jad.mansour@example.com',         '0791000015', 'hashed_password_15', 'provider', 'pending',  '2026-11-05 11:00:00'),
(16, 'Tala Rimawi',    'tala.rimawi@example.com',         '0791000016', 'hashed_password_16', 'provider', 'active',   '2026-09-08 12:00:00'),
(17, 'Ziad Haddadin',  'ziad.haddadin@example.com',       '0791000017', 'hashed_password_17', 'provider', 'inactive', '2026-09-09 13:30:00'),
(18, 'Hala Qudah',     'hala.qudah@lenslight.example.com','0791000018', 'hashed_password_18', 'provider', 'active',   '2026-09-04 09:00:00'),
(19, 'Bashar Nimri',   'bashar.nimri@goldenframe.example.com','0791000019','hashed_password_19','provider','active',   '2026-09-06 10:30:00'),
(20, 'Lama Khoury',    'lama.khoury@bloomdecor.example.com','0791000020','hashed_password_20','provider', 'active',   '2026-09-07 11:45:00'),
(21, 'Wael Zoubi',     'wael.zoubi@ammanevents.example.com','0791000021','hashed_password_21','provider', 'active',   '2026-09-11 14:00:00'),
(22, 'Dalia Sharaf',   'dalia.sharaf@cedarhall.example.com','0791000022','hashed_password_22','provider', 'active',   '2026-09-13 15:15:00'),
(23, 'Karam Awad',     'karam.awad@petra.example.com',    '0791000023', 'hashed_password_23', 'provider', 'active',   '2026-09-14 16:30:00');

-- services
INSERT INTO services (id, name) VALUES
(1, 'Photography'),
(2, 'Videography'),
(3, 'Decoration'),
(4, 'Event Planning'),
(5, 'Venues');

-- providers (provider N belongs to user N+11)
INSERT INTO providers (id, user_id, provider_type, company_name, representative_name, business_email, tagline, location, description, starting_price, pricing_unit, pricing_quantity) VALUES
(1,  12, 'individual', NULL, NULL, NULL, 'Moments that last forever',     'Amman',  'Wedding and family photographer with 6 years of experience.',        150.00,  'hour',  1),
(2,  13, 'individual', NULL, NULL, NULL, 'Stories told in motion',        'Zarqa',  'Videographer for weddings, graduations and parties.',                200.00,  'hour',  2),
(3,  14, 'individual', NULL, NULL, NULL, 'Décor with a personal touch',   'Irbid',  'Table and stage decoration for small and medium events.',            300.00,  'event', 1),
(4,  15, 'individual', NULL, NULL, NULL, 'Your event, perfectly planned', 'Amman',  'Independent event planner for private celebrations.',                500.00,  'event', 1),
(5,  16, 'individual', NULL, NULL, NULL, 'Light, color and joy',          'Aqaba',  'Portrait and event photographer.',                                   120.00,  'hour',  1),
(6,  17, 'individual', NULL, NULL, NULL, 'Simple and elegant decoration', 'Salt',   'Balloon, flower and table decoration.',                              250.00,  'event', 1),
(7,  18, 'company', 'Lens & Light Studio', 'Hala Qudah',   'info@lenslight.example.com',   'Photo and video, one team', 'Amman', 'Studio with photographers and video editors for any event.',       400.00,  'event', 1),
(8,  19, 'company', 'Golden Frame Co.',    'Bashar Nimri', 'hello@goldenframe.example.com','Every frame is gold',       'Amman', 'Professional photography for weddings and corporate events.',   350.00,  'event', 1),
(9,  20, 'company', 'Bloom Decor House',   'Lama Khoury',  'contact@bloomdecor.example.com','Where flowers meet design', 'Amman', 'Full decoration service: flowers, lighting and stage design.',    800.00,  'event', 1),
(10, 21, 'company', 'Amman Events Co.',    'Wael Zoubi',   'team@ammanevents.example.com', 'We plan, you enjoy',        'Amman', 'Event planning and decoration from idea to the last guest.',    1000.00, 'event', 1),
(11, 22, 'company', 'Cedar Hall Venues',   'Dalia Sharaf', 'booking@cedarhall.example.com','Halls for every occasion',  'Amman', 'Indoor hall and rooftop for up to 300 guests.',                 1500.00, 'day',   1),
(12, 23, 'company', 'Petra Productions',   'Karam Awad',   'studio@petra.example.com',     'Cinema quality for events', 'Amman', 'Video production and photography for events and brands.',        600.00,  'event', 1);

-- provider_services (is_main = 1 is the main service)
INSERT INTO provider_services (provider_id, service_id, is_main) VALUES
(1, 1, 1),
(2, 2, 1),
(3, 3, 1),
(4, 4, 1),
(5, 1, 1),
(6, 3, 1),
(7, 1, 1), (7, 2, 0),
(8, 1, 1),
(9, 3, 1),
(10, 4, 1), (10, 3, 0),
(11, 5, 1),
(12, 2, 1), (12, 1, 0);

-- portfolio_items
INSERT INTO portfolio_items (id, provider_id, media_type, file_url) VALUES
(1,  1,  'photo', 'uploads/provider1/photo1.jpg'),
(2,  1,  'photo', 'uploads/provider1/photo2.jpg'),
(3,  2,  'video', 'uploads/provider2/video1.mp4'),
(4,  2,  'video', 'https://www.youtube.com/watch?v=demo2'),
(5,  3,  'photo', 'uploads/provider3/photo1.jpg'),
(6,  3,  'photo', 'uploads/provider3/photo2.jpg'),
(7,  5,  'photo', 'uploads/provider5/photo1.jpg'),
(8,  6,  'photo', 'uploads/provider6/photo1.jpg'),
(9,  7,  'photo', 'uploads/provider7/photo1.jpg'),
(10, 7,  'video', 'uploads/provider7/video1.mp4'),
(11, 8,  'photo', 'uploads/provider8/photo1.jpg'),
(12, 8,  'photo', 'uploads/provider8/photo2.jpg'),
(13, 9,  'photo', 'uploads/provider9/photo1.jpg'),
(14, 9,  'photo', 'uploads/provider9/photo2.jpg'),
(15, 10, 'photo', 'uploads/provider10/photo1.jpg'),
(16, 11, 'photo', 'uploads/provider11/photo1.jpg'),
(17, 11, 'photo', 'uploads/provider11/photo2.jpg'),
(18, 12, 'video', 'uploads/provider12/video1.mp4');

-- company_employees
INSERT INTO company_employees (id, provider_id, name, specialty) VALUES
(1,  7,  'Nour Hamdan',      'Photographer'),
(2,  7,  'Omar Saleh',       'Video editor'),
(3,  8,  'Yousef Ali',       'Photographer'),
(4,  9,  'Rana Tamimi',      'Floral designer'),
(5,  9,  'Fadi Hourani',     'Stage decorator'),
(6,  10, 'Lina Abbadi',      'Event coordinator'),
(7,  11, 'Mazen Rawashdeh',  'Hall manager'),
(8,  12, 'Sami Dweik',       'Camera operator'),
(9,  12, 'Heba Naser',       'Video editor'),
(10, 12, 'Ammar Bataineh',   'Photographer');

-- projects (client_id is a user with role client)
INSERT INTO projects (id, client_id, name, event_type, location, event_date, budget, status) VALUES
(1,  2,  'Garden Wedding Celebration', 'Wedding',     'Amman',  '2026-11-18', 5000.00,  'active'),
(2,  3,  'Modern Engagement Dinner',   'Engagement',  'Zarqa',  '2026-10-30', 2500.00,  'completed'),
(3,  4,  'Graduation Celebration',     'Graduation',  'Irbid',  '2026-10-08', 1200.00,  'completed'),
(4,  5,  'Corporate Launch Night',     'Corporate',   'Amman',  '2026-12-05', 8000.00,  'pending'),
(5,  6,  'Baby Shower Brunch',         'Baby Shower', 'Amman',  '2026-11-22', 900.00,   'active'),
(6,  7,  'Henna Evening',              'Henna',       'Salt',   '2026-09-15', 1500.00,  'cancelled'),
(7,  8,  'Charity Gala',               'Charity',     'Amman',  '2026-12-20', 10000.00, 'pending'),
(8,  9,  'Birthday at the Farm',       'Birthday',    'Madaba', '2026-10-12', 700.00,   'completed'),
(9,  10, 'Product Showcase',           'Corporate',   'Amman',  '2026-11-30', 3000.00,  'active'),
(10, 11, 'Family Reunion',             'Family',      'Aqaba',  '2026-11-14', 1800.00,  'active'),
(11, 2,  'Anniversary Dinner',         'Anniversary', 'Amman',  '2026-10-25', 1000.00,  'completed'),
(12, 3,  'Summer Rooftop Party',       'Party',       'Amman',  '2026-08-20', 2200.00,  'completed');

-- requests
INSERT INTO requests (id, project_id, provider_id, service_id, description, event_date, start_time, end_time, status, deadline, created_at) VALUES
(1,  1,  7,  1, 'Wedding photography for the outdoor ceremony and reception', '2026-11-18', '16:00', '22:00', 'accepted', '2026-10-20', '2026-10-05 10:00:00'),
(2,  1,  9,  3, 'Garden decoration with a sage and ivory theme',               '2026-11-18', '10:00', '16:00', 'accepted', '2026-10-20', '2026-10-05 10:30:00'),
(3,  1,  7,  2, 'Short highlight video of the ceremony',                       '2026-11-18', '16:00', '22:00', 'pending',  '2026-10-25', '2026-10-06 09:00:00'),
(4,  2,  3,  3, 'Table and stage decoration with a modern theme',              '2026-10-30', '14:00', '18:30', 'accepted', '2026-10-14', '2026-10-01 12:00:00'),
(5,  2,  1,  1, 'Photos for the engagement dinner',                            '2026-10-30', '18:30', '23:00', 'accepted', '2026-10-14', '2026-10-01 12:20:00'),
(6,  3,  2,  2, 'Event videography and a short recap video',                   '2026-10-08', '17:00', '21:00', 'accepted', '2026-10-05', '2026-09-25 15:00:00'),
(7,  3,  5,  1, 'Family portraits and ceremony photos',                        '2026-10-08', '17:00', '21:00', 'accepted', '2026-10-05', '2026-09-25 15:30:00'),
(8,  4,  10, 4, 'Full planning for a product launch night',                    '2026-12-05', '18:00', '23:00', 'pending',  '2026-11-20', '2026-11-02 09:15:00'),
(9,  4,  12, 2, 'Video coverage for the launch night',                         '2026-12-05', '18:00', '23:00', 'new',      '2026-11-25', '2026-11-06 14:00:00'),
(10, 4,  11, 5, 'Hall for 150 guests',                                         '2026-12-05', '17:00', '23:00', 'new',      '2026-11-25', '2026-11-06 14:30:00'),
(11, 5,  9,  3, 'Pastel decoration for a baby shower brunch',                  '2026-11-22', '09:00', '13:00', 'accepted', '2026-11-10', '2026-10-28 11:00:00'),
(12, 5,  8,  1, 'Photos for the brunch',                                       '2026-11-22', '10:00', '13:00', 'pending',  '2026-11-12', '2026-10-29 16:00:00'),
(13, 6,  3,  3, 'Henna night decoration',                                      '2026-09-15', '18:00', '23:00', 'expired',  '2026-09-01', '2026-08-20 10:00:00'),
(14, 6,  1,  1, 'Henna evening photography',                                   '2026-09-15', '18:00', '23:00', 'rejected', '2026-09-01', '2026-08-20 10:20:00'),
(15, 7,  11, 5, 'Venue for a charity gala',                                    '2026-12-20', '18:00', '23:00', 'new',      '2026-12-01', '2026-11-05 10:00:00'),
(16, 7,  10, 4, 'Event planning for the charity gala',                         '2026-12-20', '18:00', '23:00', 'pending',  '2026-12-01', '2026-11-04 13:00:00'),
(17, 8,  5,  1, 'Birthday photos at the farm',                                 '2026-10-12', '12:00', '16:00', 'accepted', '2026-10-05', '2026-09-28 10:00:00'),
(18, 8,  2,  2, 'Birthday video',                                              '2026-10-12', '12:00', '16:00', 'rejected', '2026-10-05', '2026-09-28 10:10:00'),
(19, 9,  12, 1, 'Product photos and event coverage',                           '2026-11-30', '10:00', '15:00', 'accepted', '2026-11-15', '2026-10-30 09:00:00'),
(20, 9,  8,  1, 'Extra photographer for the showcase',                         '2026-11-30', '10:00', '15:00', 'new',      '2026-11-15', '2026-11-06 08:30:00'),
(21, 10, 1,  1, 'Family reunion photos on the beach',                          '2026-11-14', '15:00', '19:00', 'pending',  '2026-11-10', '2026-11-01 17:00:00'),
(22, 10, 7,  2, 'Video recap of the reunion',                                  '2026-11-14', '15:00', '19:00', 'accepted', '2026-11-10', '2026-11-01 17:30:00'),
(23, 11, 10, 4, 'Plan a small anniversary dinner',                             '2026-10-25', '19:00', '23:00', 'accepted', '2026-10-15', '2026-10-08 12:00:00'),
(24, 12, 11, 5, 'Rooftop hall for a summer party',                             '2026-08-20', '19:00', '23:00', 'accepted', '2026-08-10', '2026-07-28 11:00:00'),
(25, 12, 12, 2, 'Party video and highlights',                                  '2026-08-20', '19:00', '23:00', 'accepted', '2026-08-10', '2026-07-28 11:30:00');

-- reviews (only for accepted requests of completed projects, one per request)
INSERT INTO reviews (id, request_id, rating, comment, created_at) VALUES
(1, 4,  5, 'Beautiful decoration, exactly what we wanted.',          '2026-11-01 10:00:00'),
(2, 5,  4, 'Great photos, delivered a little late.',                 '2026-11-02 11:30:00'),
(3, 6,  5, 'Very professional video.',                               '2026-10-10 09:45:00'),
(4, 7,  5, 'Friendly photographer and lovely portraits.',            '2026-10-10 10:15:00'),
(5, 17, 4, NULL,                                                     '2026-10-14 18:00:00'),
(6, 23, 5, 'The dinner was perfectly organized.',                    '2026-10-27 20:00:00'),
(7, 24, 4, 'Great hall and a helpful team.',                         '2026-08-22 12:00:00'),
(8, 25, 3, 'Good video but the editing took a long time.',           '2026-08-25 15:30:00');

-- subscription_plans (same plan names, different price for individual and company)
INSERT INTO subscription_plans (id, name, provider_type, price) VALUES
(1, 'Free',         'individual', 0.00),
(2, 'Professional', 'individual', 9.99),
(3, 'Business',     'individual', 14.99),
(4, 'Free',         'company',    0.00),
(5, 'Professional', 'company',    19.99),
(6, 'Business',     'company',    29.99);

-- subscriptions
INSERT INTO subscriptions (id, provider_id, plan_id, status, start_date, renewal_date) VALUES
(1,  1,  2, 'active',    '2026-09-01', '2026-12-01'),
(2,  2,  1, 'active',    '2026-08-10', NULL),
(3,  3,  3, 'active',    '2026-11-01', '2026-12-01'),
(4,  4,  1, 'pending',   '2026-11-05', NULL),
(5,  5,  2, 'active',    '2026-07-15', '2026-12-15'),
(6,  6,  2, 'expired',   '2026-05-01', '2026-08-01'),
(7,  7,  6, 'active',    '2026-09-20', '2026-12-20'),
(8,  8,  5, 'active',    '2026-10-10', '2026-11-10'),
(9,  9,  6, 'active',    '2026-08-01', '2026-12-01'),
(10, 10, 5, 'active',    '2026-09-01', '2026-12-01'),
(11, 11, 4, 'active',    '2026-06-01', NULL),
(12, 12, 5, 'cancelled', '2026-03-01', '2026-06-01');

-- transactions (payer is the client of the project, commission = 15%)
INSERT INTO transactions (id, project_id, payer_id, amount, commission, method, status, created_at) VALUES
(1,  1,  2,  1500.00, 225.00, 'Visa', 'successful', '2026-10-10 10:00:00'),
(2,  1,  2,  1000.00, 150.00, 'Visa', 'successful', '2026-10-25 10:00:00'),
(3,  2,  3,  800.00,  120.00, 'Visa', 'successful', '2026-10-05 12:00:00'),
(4,  2,  3,  450.00,  67.50,  'Visa', 'successful', '2026-10-20 12:30:00'),
(5,  3,  4,  600.00,  90.00,  'Visa', 'successful', '2026-09-30 14:00:00'),
(6,  6,  7,  500.00,  75.00,  'Visa', 'refunded',   '2026-08-25 16:00:00'),
(7,  5,  6,  400.00,  60.00,  'Visa', 'successful', '2026-11-01 09:30:00'),
(8,  5,  6,  300.00,  45.00,  'Visa', 'pending',    '2026-11-06 09:30:00'),
(9,  8,  9,  350.00,  52.50,  'Visa', 'successful', '2026-10-02 11:00:00'),
(10, 9,  10, 1200.00, 180.00, 'Visa', 'pending',    '2026-11-05 13:00:00'),
(11, 10, 11, 700.00,  105.00, 'Visa', 'failed',     '2026-11-03 17:45:00'),
(12, 11, 2,  600.00,  90.00,  'Visa', 'successful', '2026-10-12 19:00:00'),
(13, 12, 3,  1500.00, 225.00, 'Visa', 'successful', '2026-08-05 12:00:00'),
(14, 12, 3,  500.00,  75.00,  'Visa', 'successful', '2026-08-18 12:00:00'),
(15, 4,  5,  2000.00, 300.00, 'Visa', 'pending',    '2026-11-06 15:00:00');

-- messages (provider N has user id N+11)
INSERT INTO messages (id, project_id, sender_id, receiver_id, body, sent_at) VALUES
(1,  1,  2,  18, 'Hi, are you available on November 18?',                              '2026-10-04 10:00:00'),
(2,  1,  18, 2,  'Hello Sara, yes I am available. What hours do you need?',            '2026-10-04 10:20:00'),
(3,  1,  2,  18, 'From 4 PM to 10 PM.',                                                '2026-10-04 10:25:00'),
(4,  1,  18, 2,  'Perfect, I will send you the package details.',                      '2026-10-04 10:40:00'),
(5,  1,  2,  20, 'Hello, I would like a garden theme with sage and ivory colors.',     '2026-10-04 12:00:00'),
(6,  1,  20, 2,  'Sounds lovely, I can prepare a mood board for you.',                 '2026-10-04 12:30:00'),
(7,  2,  3,  14, 'Can you decorate the table and the stage?',                          '2026-09-30 09:00:00'),
(8,  2,  14, 3,  'Yes, setup and teardown are included.',                              '2026-09-30 09:30:00'),
(9,  2,  3,  12, 'Do you offer a highlight gallery?',                                  '2026-09-30 11:00:00'),
(10, 2,  12, 3,  'Yes, within 7 days after the event.',                                '2026-09-30 11:20:00'),
(11, 3,  4,  13, 'Do you cover graduation ceremonies?',                                '2026-09-24 15:00:00'),
(12, 3,  13, 4,  'Yes, I recorded many graduations before.',                           '2026-09-24 15:10:00'),
(13, 3,  4,  16, 'Can you take family portraits too?',                                 '2026-09-24 15:30:00'),
(14, 3,  16, 4,  'Of course, 30 minutes is enough.',                                   '2026-09-24 15:45:00'),
(15, 5,  6,  20, 'Do you have pastel colors for a baby shower?',                       '2026-10-27 10:00:00'),
(16, 5,  20, 6,  'Yes, we have blush pink, mint and cream.',                           '2026-10-27 10:30:00'),
(17, 9,  10, 23, 'We need coverage for our product showcase.',                         '2026-10-29 09:00:00'),
(18, 9,  23, 10, 'We can send you a quote today.',                                      '2026-10-29 09:20:00'),
(19, 10, 11, 12, 'Is the beach location a problem for you?',                           '2026-10-31 16:00:00'),
(20, 10, 12, 11, 'Not at all, I travel to Aqaba often.',                               '2026-10-31 16:15:00'),
(21, 10, 11, 18, 'Can you also record a short video?',                                 '2026-10-31 16:30:00'),
(22, 10, 18, 11, 'Yes, a 2 minute recap is included in our package.',                  '2026-10-31 16:50:00'),
(23, 12, 3,  22, 'Is the rooftop available on August 20?',                             '2026-07-27 12:00:00'),
(24, 12, 22, 3,  'Yes, we can reserve it for you from 7 PM.',                          '2026-07-27 12:30:00');

-- notifications
INSERT INTO notifications (id, user_id, title, is_read, created_at) VALUES
(1,  18, 'New project request received',        1, '2026-10-05 10:01:00'),
(2,  20, 'New project request received',        1, '2026-10-05 10:31:00'),
(3,  2,  'Your request was accepted',           1, '2026-10-06 09:00:00'),
(4,  14, 'Payment received',                    1, '2026-10-05 12:05:00'),
(5,  3,  'Please rate your experience',         1, '2026-10-31 09:00:00'),
(6,  21, 'New project request received',        0, '2026-11-02 09:16:00'),
(7,  23, 'New project request received',        0, '2026-11-06 14:01:00'),
(8,  22, 'New project request received',        0, '2026-11-06 14:31:00'),
(9,  11, 'Payment failed, please try again',    0, '2026-11-03 17:46:00'),
(10, 6,  'Payment is being processed',          0, '2026-11-06 09:31:00'),
(11, 1,  'New provider waiting for approval',   0, '2026-11-05 11:01:00'),
(12, 15, 'Your account is under review',        1, '2026-11-05 11:05:00'),
(13, 19, 'Subscription renews on November 10',  0, '2026-11-07 08:00:00'),
(14, 12, 'You received a new message',          1, '2026-10-31 16:01:00'),
(15, 10, 'Your request was accepted',           0, '2026-11-01 10:00:00'),
(16, 4,  'Please rate your experience',         1, '2026-10-09 09:00:00'),
(17, 9,  'Please rate your experience',         1, '2026-10-13 09:00:00'),
(18, 1,  'A support ticket was submitted',      0, '2026-11-06 20:00:00');

-- support_tickets (user_id can be empty)
INSERT INTO support_tickets (id, user_id, contact_email, issue_type, subject, message, status, created_at) VALUES
(1, 11,   'maya.qasem@example.com',  'Payment Issue',         NULL,                       'My payment failed but the money left my card.',                     'open',        '2026-11-03 18:00:00'),
(2, 2,    'sara.omar@example.com',   'Communication Issue',   NULL,                       'The provider has not replied for two days.',                        'in_progress', '2026-10-20 12:00:00'),
(3, 7,    'dana.mansour@example.com','Provider Issue',        NULL,                       'The provider cancelled one day before the event.',                  'closed',      '2026-09-10 09:30:00'),
(4, NULL, 'guest1@example.com',      'Technical Issue',       NULL,                       'The login page shows an error after I enter my password.',          'open',        '2026-11-04 14:10:00'),
(5, 16,   'tala.rimawi@example.com', 'Booking or Scheduling', NULL,                       'I cannot change the available times in my profile.',                'in_progress', '2026-10-28 10:20:00'),
(6, 5,    'rania.saleh@example.com', 'Project Issue',         NULL,                       'I want to change the date of my project.',                          'open',        '2026-11-06 11:00:00'),
(7, NULL, 'guest2@example.com',      'Others',                'Partnership question',     'Do you work with event companies outside Jordan?',                  'closed',      '2026-10-02 16:40:00'),
(8, 21,   'wael.zoubi@ammanevents.example.com', 'Others',     'Invoice for my subscription','Can I get an invoice for my Professional plan?',                  'open',        '2026-11-06 19:30:00');

-- ai_conversations
INSERT INTO ai_conversations (id, user_id, title, created_at) VALUES
(1, 2,  'Wedding decoration ideas',      '2026-10-02 20:00:00'),
(2, 6,  'Baby shower menu and theme',    '2026-10-26 18:30:00'),
(3, 5,  'Corporate launch checklist',    '2026-10-31 11:00:00'),
(4, 11, 'Family reunion on the beach',   '2026-10-30 21:15:00');

-- ai_messages
INSERT INTO ai_messages (id, conversation_id, sender, body, sent_at) VALUES
(1,  1, 'user', 'Give me ideas for a garden wedding decoration.',                                   '2026-10-02 20:00:00'),
(2,  1, 'ai',   'Try sage and ivory colors, hanging lights, and a flower arch at the entrance.',    '2026-10-02 20:00:10'),
(3,  1, 'user', 'What is a good budget for decoration?',                                            '2026-10-02 20:02:00'),
(4,  1, 'ai',   'For around 150 guests, many couples spend between 800 and 1500 JOD.',             '2026-10-02 20:02:10'),
(5,  2, 'user', 'I need a theme for a baby shower brunch.',                                         '2026-10-26 18:30:00'),
(6,  2, 'ai',   'A pastel theme with blush pink, mint and cream works very well for brunch.',       '2026-10-26 18:30:08'),
(7,  3, 'user', 'What should I prepare for a product launch night?',                                '2026-10-31 11:00:00'),
(8,  3, 'ai',   'Start with the venue, the guest list, a video team, and a simple schedule.',       '2026-10-31 11:00:09'),
(9,  4, 'user', 'Which services do I need for a beach family reunion?',                             '2026-10-30 21:15:00'),
(10, 4, 'ai',   'A photographer, a small decoration setup, and shade tents are usually enough.',    '2026-10-30 21:15:07');
GO

/* ============================================================
   PART 3: QUICK CHECK  (should show 17 rows)
   ============================================================ */
SELECT 'users' AS table_name, COUNT(*) AS rows_count FROM users
UNION ALL SELECT 'providers',          COUNT(*) FROM providers
UNION ALL SELECT 'services',           COUNT(*) FROM services
UNION ALL SELECT 'provider_services',  COUNT(*) FROM provider_services
UNION ALL SELECT 'portfolio_items',    COUNT(*) FROM portfolio_items
UNION ALL SELECT 'company_employees',  COUNT(*) FROM company_employees
UNION ALL SELECT 'projects',           COUNT(*) FROM projects
UNION ALL SELECT 'requests',           COUNT(*) FROM requests
UNION ALL SELECT 'reviews',            COUNT(*) FROM reviews
UNION ALL SELECT 'subscription_plans', COUNT(*) FROM subscription_plans
UNION ALL SELECT 'subscriptions',      COUNT(*) FROM subscriptions
UNION ALL SELECT 'transactions',       COUNT(*) FROM transactions
UNION ALL SELECT 'messages',           COUNT(*) FROM messages
UNION ALL SELECT 'notifications',      COUNT(*) FROM notifications
UNION ALL SELECT 'support_tickets',    COUNT(*) FROM support_tickets
UNION ALL SELECT 'ai_conversations',   COUNT(*) FROM ai_conversations
UNION ALL SELECT 'ai_messages',        COUNT(*) FROM ai_messages;
GO