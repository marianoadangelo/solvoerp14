-- Delete orphan attachment relations
DELETE FROM message_attachment_rel m WHERE NOT EXISTS (SELECT 1 FROM mail_message mm WHERE mm.id = m.message_id);

-- Delete orphan attachment relations (ir_attachment)
DELETE FROM message_attachment_rel m WHERE NOT EXISTS (SELECT 1 FROM ir_attachment ia WHERE ia.id = m.attachment_id);

-- Delete orphan mail message partner relations
DELETE FROM mail_message_res_partner_rel m WHERE NOT EXISTS (SELECT 1 FROM mail_message mm WHERE mm.id = m.mail_message_id);

-- Delete conflicting group before migration
DELETE FROM res_groups WHERE name = 'Allow to define fiscal years of more or less than a year';

-- Fix duplicate account_move sequence numbers for posted entries.
-- Odoo v14 requires unique (name, journal_id, move_type) per posted entry.
-- In v13, Argentine fiscal documents (OP-X, RE-X, etc.) could share the same
-- number for multiple entries in the same journal. We rename duplicates by
-- appending '-M-<id>' to make them unique, keeping the first entry (by id) unchanged.
UPDATE account_move
SET name = name || '-M-' || id::text
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY name, journal_id ORDER BY id) AS rn
        FROM account_move
        WHERE state = 'posted'
        AND name IS NOT NULL
        AND name != '/'
        AND name != ''
    ) ranked
    WHERE rn > 1
);