WITH RECURSIVE
eligible_campaigns AS (
    SELECT id, parent_id
    FROM campaign
    WHERE merchant_id = 501
      AND name LIKE '%Diwali%'
      AND creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND processing_status = 'processed'
),
campaign_hierarchy AS (
    SELECT id AS campaign_id, id AS root_campaign_id
    FROM eligible_campaigns
    WHERE parent_id IS NULL
    UNION ALL
    SELECT ec.id, ch.root_campaign_id
    FROM eligible_campaigns ec
    JOIN campaign_hierarchy ch ON ec.parent_id = ch.campaign_id
),
family_stats AS (
    SELECT campaign_id, root_campaign_id,
           COUNT(*) OVER (PARTITION BY root_campaign_id) AS family_size
    FROM campaign_hierarchy
),
qualifying_sends AS (
    SELECT cl.id, cl.customer_id, fs.root_campaign_id, fs.family_size
    FROM communication_log cl
    JOIN family_stats fs ON cl.communication_id = fs.campaign_id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND cl.delivery_status = 900
      AND cl.sent_time >= '2026-10-01 00:00:00'
      AND cl.sent_time <  '2026-11-01 00:00:00'
)
SELECT
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT root_campaign_id, customer_id
        FROM qualifying_sends WHERE family_size > 1
    )) 
    +
    (SELECT COUNT(*) FROM qualifying_sends WHERE family_size = 1)
    AS target_base;
