WITH RECURSIVE campaign_hierarchy AS (
    SELECT
        id AS campaign_id,
        id AS root_campaign_id,
        parent_id
    FROM campaign
    WHERE parent_id IS NULL
      AND creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND processing_status = 'processed'
    UNION ALL
    SELECT
        c.id AS campaign_id,
        ch.root_campaign_id,
        c.parent_id
    FROM campaign c
    JOIN campaign_hierarchy ch
      ON c.parent_id = ch.campaign_id
    WHERE c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
),
campaign_chain_counts AS (
    SELECT
        root_campaign_id,
        COUNT(*) AS chain_size
    FROM campaign_hierarchy
    GROUP BY root_campaign_id
),
tagged_sends AS (
    SELECT
        cl.id AS log_id,
        cl.customer_id,
        ch.root_campaign_id,
        ccc.chain_size
    FROM communication_log cl
    JOIN campaign_hierarchy ch
      ON cl.communication_id = ch.campaign_id
    JOIN campaign_chain_counts ccc
      ON ch.root_campaign_id = ccc.root_campaign_id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
)
SELECT
    (
        SELECT COUNT(
            DISTINCT root_campaign_id || '-' || customer_id
        )
        FROM tagged_sends
        WHERE chain_size > 1
    )
    +
    (
        SELECT COUNT(*)
        FROM tagged_sends
        WHERE chain_size = 1
    ) AS target_base;
