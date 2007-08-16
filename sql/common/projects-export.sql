
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (24, 'project_csv', 'view_projects', 1400);



---------------------------------------------------------
-- Projects CSV

--
delete from im_view_columns where view_id=24;
--


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2401,24,NULL,'Nr','$project_nr','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2403,24,NULL,'Name','$project_name','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2405,24,NULL,'Customer','$company_name','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2407,24,NULL,'Parent','$parent_project_nr','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2408,24,NULL,'SubProj','$subproject_level','','',8,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2409,24,NULL,'Type','$project_type','','',9,'');





insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2411,24,NULL,'PM','$lead_name','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2413,24,NULL,'Key Account','$keyacc_name','','',13,'');



insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2421,24,NULL,'Status','$project_status','','',21,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2423,24,NULL,'PM','$lead_email','','',23,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2431,24,NULL,'Start','$start_date','','',31,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2433,24,NULL,'StartMonth','$start_month','','',33,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2435,24,NULL,'StartYear','$start_year','','',35,'');



insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2437,24,NULL,'End','$end_date','','',37,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2438,24,NULL,'EndMonth','$end_month','','',38,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2439,24,NULL,'EndYear','$end_year','','',39,'');

-- 2440 - 2459 Reserved for Translation

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2471,24,NULL,'OnTrack','$on_track_status','','',71,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2472,24,NULL,'Completed','$percent_completed','','',72,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2473,24,NULL,'Budget','$project_budget','','',73,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2475,24,NULL,'BudgetCur','$project_budget_currency','','',75,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2477,24,NULL,'BudgetHours','$project_budget_hours','','',77,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2478,24,NULL,'LoggedHours','$reported_hours_cache','','',78,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2479,24,NULL,'Billing','$billing_type','','',79,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2481,24,NULL,'Invoices','$cost_invoices_cache','','',81,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2482,24,NULL,'Bills','$cost_bills_cache','','',82,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2483,24,NULL,'TimeCosts','$cost_timesheet_logged_cache','','',83,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2486,24,NULL,'Quotes','$cost_quotes_cache','','',86,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2487,24,NULL,'POs','$cost_purchase_orders_cache','','',87,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2488,24,NULL,'TimeEstim','$cost_timesheet_planned_cache','','',88,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2489,24,NULL,'DelNotes','$cost_delivery_notes_cache','','',89,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2491,24,NULL,'Expenses','$cost_expense_logged_cache','','',91,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2493,24,NULL,'Description','$description','','',93,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2495,24,NULL,'Note','$note','','',95,'');



