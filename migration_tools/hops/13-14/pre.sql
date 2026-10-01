-- Hop 13 -> 14, before OpenUpgrade (13 schema). Run by the inova_cp upgrade worker on every
-- 13 -> 14 migration (see migration_tools/hops/README.md in the sodoo repo).
--
-- account 14.0 end-migration (harmonize_groups) regenerates the account groups from the
-- chart template and fails with "Account Groups with the same granularity can't overlap"
-- when the 13 groups of the l10n_ar chart (dotted code_prefix 1.1.1...) are still there.
-- Drop only the groups created by l10n_ar (by xmlid); 14 creates them again from the chart.
-- Safe to run twice; does nothing on databases without l10n_ar groups.

BEGIN;

CREATE TEMP TABLE _inova_ar_groups ON COMMIT DROP AS
SELECT res_id AS id FROM ir_model_data WHERE model = 'account.group' AND module = 'l10n_ar';

UPDATE account_account SET group_id = NULL WHERE group_id IN (SELECT id FROM _inova_ar_groups);
UPDATE account_group SET parent_id = NULL WHERE parent_id IN (SELECT id FROM _inova_ar_groups);
DELETE FROM account_group WHERE id IN (SELECT id FROM _inova_ar_groups);
DELETE FROM ir_model_data WHERE model = 'account.group' AND module = 'l10n_ar';

COMMIT;
