
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (205, 'timesheet_csv', 'view_timesheet', 1400);



---------------------------------------------------------
-- Timesheet CSV

--
delete from im_view_columns where view_id=205;
--

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20500,205,NULL,'Username','$username','','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20501,205,NULL,'First','$first_names','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20503,205,NULL,'Last','$last_name','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20505,205,NULL,'Email','$email','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20507,205,NULL,'Supervisor','$supervisor_name','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20509,205,NULL,'Hourly Cost','$hourly_cost','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
205011,205,NULL,'Cost Center Code','$cost_center_code','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20513,205,NULL,'Date','$day_formatted','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20515,205,NULL,'Top Project Nr','$top_project_nr','','',15,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20517,205,NULL,'Top Project Name','$top_project_name','','',17,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20519,205,NULL,'Parent Project Nr','$parent_project_nr','','',19,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20521,205,NULL,'Parent Project Name','$parent_project_name','','',21,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20523,205,NULL,'Task Nr','$project_nr','','',23,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20525,205,NULL,'Task Name','$project_name','','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20527,205,NULL,'Customer Nr','$customer_path','','',27,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20529,205,NULL,'Customer','$customer_name','','',29,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20531,205,NULL,'Hours','$hours','','',31,'');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
20599,205,NULL,'Note','$hours_note','','',99,'');




