-- /packages/intranet-dw-light/sql/postgresql/intranet-dw-light-create.sql
--
-- Copyright (c) 2003-2005 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- CSV export of several business objects suitable
-- for Excel Pivot Tables.


---------------------------------------------------------
-- Setup a "Export Company CSV" admin link in "companies"
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_admin_menu		integer;

        -- Groups
        v_senman                integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''companies_admin'';

    -- Create a "Export Companies CSV" link under "Companies"
    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-dw-light'',     -- package_name
        ''companies_admin_csv'',    -- label
        ''Export Companies CSV'',    -- name
        ''/intranet-dw-light/companies.csv'', -- url
        10,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                     -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Setup a "Export Customer Invoices CSV" admin link in
-- "Customer Invoices"
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_main_menu		integer;

        -- Groups
        v_senman                integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''invoices_customers'';

    -- Create a "Export Invoices CSV" link
    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-dw-light'',     -- package_name
        ''invoices_customers_csv'',    -- label
        ''Export Customer Invoices CSV'',    -- name
        ''/intranet-dw-light/invoices.csv?cost_type_id=3708'', -- url
        990,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                     -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Setup a "Export Provider Invoices CSV" admin link in
-- "Provider Invoices"
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_main_menu		integer;

        -- Groups
        v_senman                integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''invoices_providers'';

    -- Create a "Export Invoices CSV" link
    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-dw-light'',     -- package_name
        ''invoices_providers_csv'',    -- label
        ''Export Provider Invoices CSV'',    -- name
        ''/intranet-dw-light/invoices.csv?cost_type_id=3710'', -- url
        990,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                     -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();








\i ../common/companies-export.sql
\i ../common/invoices-export.sql

