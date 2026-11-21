-- Row counts (expected: 7043 / 7043 / 9 / 63387)
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL SELECT 'services', COUNT(*) FROM services
UNION ALL SELECT 'subscription_services', COUNT(*) FROM subscription_services;

-- View each table (run one at a time)
SELECT * FROM locations             ORDER BY zip_code        LIMIT 20;
SELECT * FROM customers             ORDER BY customer_id     LIMIT 20;
SELECT * FROM subscriptions         ORDER BY subscription_id LIMIT 20;
SELECT * FROM services              ORDER BY service_id;
SELECT * FROM subscription_services ORDER BY subscription_id, service_id LIMIT 20;

-- Everything joined together
SELECT c.customer_id, l.city, l.state, c.gender,
       s.tenure_months, s.contract_type, s.monthly_charges, s.churned,
       sv.service_name, ss.status
FROM customers c
JOIN locations l              ON l.zip_code = c.zip_code
JOIN subscriptions s          ON s.customer_id = c.customer_id
JOIN subscription_services ss ON ss.subscription_id = s.subscription_id
JOIN services sv              ON sv.service_id = ss.service_id
ORDER BY c.customer_id, sv.service_id
LIMIT 100;
