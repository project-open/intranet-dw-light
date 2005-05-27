

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (3, 'company_csv', 'view_companies', 1400);




---------------------------------------------------------
-- Companies CSV

--
delete from im_view_columns where column_id >= 300 and column_id <= 399;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(303,3,NULL,'Path','$company_path','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(304,3,NULL,'Name','$company_name','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(305,3,NULL,'Type','$company_type','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(307,3,NULL,'Status','$company_status','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(321,3,NULL,'Billable','$billable_p','','',21,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(323,3,NULL,'VAT','$vat_number','','',23,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(325,3,NULL,'Phone','$phone','','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(327,3,NULL,'Fax','$fax','','',27,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(329,3,NULL,'Addr1','$address_line1','','',29,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(331,3,NULL,'Addr2','$address_line2','','',31,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(333,3,NULL,'City','$address_city','','',33,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(335,3,NULL,'ZIP','$address_postal_code','','',35,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(337,3,NULL,'Country','$address_country_code','','',37,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(341,3,NULL,'Contact','$company_contact_email','','',41,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(343,3,NULL,'Accounting','$accounting_contact_email','','',43,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(345,3,NULL,'Referral','$referral_source','','',45,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(347,3,NULL,'AnRev','$annual_revenue','','',47,'');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values 
(351,3,NULL,'Note','$note','','',51,'');

