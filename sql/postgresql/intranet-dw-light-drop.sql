-- /packages/intranet-dw-light/sql/oracle/intranet-dw-light-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



---------------------------------------------------------
-- delete potentially existing menus and plugins

select im_component_plugin__del_module('intranet-dw-light');
select im_menu__del_module('intranet-dw-light');



-- Delete company_csv
delete from im_view_columns where view_id = 3;
delete from im_views where view_id = 3;

-- Delete projects_csv
delete from im_view_columns where view_id = 24;
delete from im_views where view_id = 24;

-- Delete invoices_csv
delete from im_view_columns where view_id = 34;
delete from im_views where view_id = 34;





