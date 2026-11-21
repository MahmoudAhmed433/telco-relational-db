-- Source table: staging_customers (never modified)

-- 1) Reset the 5 normalized tables
DROP TABLE IF EXISTS subscription_services CASCADE;
DROP TABLE IF EXISTS subscriptions         CASCADE;
DROP TABLE IF EXISTS customers             CASCADE;
DROP TABLE IF EXISTS services              CASCADE;
DROP TABLE IF EXISTS locations             CASCADE;

-- 2) Create tables
CREATE TABLE locations (
    zip_code  VARCHAR(10) PRIMARY KEY,
    country   VARCHAR(50),
    state     VARCHAR(50),
    city      VARCHAR(50),
    latitude  DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

CREATE TABLE customers (
    customer_id    VARCHAR(20) PRIMARY KEY,
    zip_code       VARCHAR(10) REFERENCES locations(zip_code),
    gender         VARCHAR(10),
    senior_citizen BOOLEAN,
    partner        BOOLEAN,
    dependents     BOOLEAN
);

CREATE TABLE subscriptions (
    subscription_id   SERIAL PRIMARY KEY,
    customer_id       VARCHAR(20) REFERENCES customers(customer_id),
    tenure_months     INT,
    contract_type     VARCHAR(30),
    paperless_billing BOOLEAN,
    payment_method    VARCHAR(50),
    monthly_charges   DECIMAL(10,2),
    total_charges     DECIMAL(10,2),
    churned           BOOLEAN,
    churn_score       INT,
    cltv              INT,
    churn_reason      VARCHAR(100)
);

CREATE TABLE services (
    service_id   SERIAL PRIMARY KEY,
    service_name VARCHAR(50) UNIQUE,
    category     VARCHAR(30)
);

CREATE TABLE subscription_services (
    subscription_id INT REFERENCES subscriptions(subscription_id),
    service_id      INT REFERENCES services(service_id),
    status          VARCHAR(30),
    PRIMARY KEY (subscription_id, service_id)
);

-- 3) Move the data (order matters because of the foreign keys)
INSERT INTO locations
SELECT DISTINCT ON (zip_code) zip_code, country, state, city,
       latitude::numeric(9,6), longitude::numeric(9,6)
FROM staging_customers
ORDER BY zip_code;

INSERT INTO customers
SELECT customer_id, zip_code, gender,
       senior_citizen = 'Yes', partner = 'Yes', dependents = 'Yes'
FROM staging_customers;

INSERT INTO subscriptions
    (customer_id, tenure_months, contract_type, paperless_billing, payment_method,
     monthly_charges, total_charges, churned, churn_score, cltv, churn_reason)
SELECT customer_id, tenure_months::int, contract, paperless_billing = 'Yes', payment_method,
       monthly_charges::numeric(10,2),
       NULLIF(TRIM(total_charges::text), '')::numeric(10,2),
       churn_label = 'Yes', churn_score::int, cltv::int, churn_reason
FROM staging_customers;

INSERT INTO services (service_name, category) VALUES
    ('Phone Service',    'Phone'),
    ('Multiple Lines',   'Phone'),
    ('Internet Service', 'Internet'),
    ('Online Security',  'Add-on'),
    ('Online Backup',    'Add-on'),
    ('Device Protection','Add-on'),
    ('Tech Support',     'Add-on'),
    ('Streaming TV',     'Streaming'),
    ('Streaming Movies', 'Streaming');

INSERT INTO subscription_services (subscription_id, service_id, status)
SELECT s.subscription_id, sv.service_id, v.status
FROM staging_customers t
JOIN subscriptions s ON s.customer_id = t.customer_id
CROSS JOIN LATERAL (VALUES
    ('Phone Service',    t.phone_service),
    ('Multiple Lines',   t.multiple_lines),
    ('Internet Service', t.internet_service),
    ('Online Security',  t.online_security),
    ('Online Backup',    t.online_backup),
    ('Device Protection',t.device_protection),
    ('Tech Support',     t.tech_support),
    ('Streaming TV',     t.streaming_tv),
    ('Streaming Movies', t.streaming_movies)
) AS v(service_name, status)
JOIN services sv ON sv.service_name = v.service_name;
