-- Migration: 20261127110000_i2_fix_units_rls_correlated_id.sql
-- Scope: Fix correlated subquery column shadowing in units_select_via_project_association
--        (`upa.unit_id = units.id` instead of unqualified `id` which resolved to `upa.id`).
--        Never alters migrations 1-14.

DROP POLICY IF EXISTS units_select_via_project_association ON public.units;

CREATE POLICY units_select_via_project_association ON public.units
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.unit_project_associations upa
      WHERE upa.unit_id = units.id AND app_internal.has_project_access(upa.project_id)
    )
  );
