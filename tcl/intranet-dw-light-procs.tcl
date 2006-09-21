# /packages/intranet-dw-light/tcl/intranet-dw-light-procs.tcl

ad_library {
    Data Warehouse Light
    @author frank.bergmann@project-open.com
    @creation-date  26.5.2005
}


# -----------------------------------------------------------
# Web page registrations
# -----------------------------------------------------------

# Invoice CSV export doesn't work with a regular TCL
# file, so we have to register a procedure here instead
# of the web page.
ad_register_proc GET "/intranet-dw-light/*.csv" im_dw_light_handler


# -----------------------------------------------------------
# Handle calls in /intranet-dw-light/xxxx.csv
# -----------------------------------------------------------

ad_proc im_dw_light_handler { } {  
    This procedure gets called for all page requests in
    /intranet-dw-light . In particular, it serves pages like:
    /intranet-dw-light/xxxx.csv
} {
    set url [ns_conn url]
    set query [ns_conn query]
    set user_id [ad_maybe_redirect_for_registration]

    ns_log Notice "im_dw_light_handler: url=$url"

    # Serve page. Example:
    # /intranet-dw-light/invoices.csv?cost_type_id=1234
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # skip: +0:/ +1:intranet-dw-light, +2:filename
    set filename [lindex $path_list 2]
    ns_log Notice "im_dw_light_handler: filename=$filename"
    
    set file_pieces [split $filename {.}]
    set file_body [lindex $file_pieces 0]
    set file_ext [lindex $file_pieces 1]

    if {![string equal $file_ext "csv"]} {
	ad_return_complaint 1 "Invalid file extension<br>
        You have specified an invalid file extension."
	return
    }

    switch $file_body {
	companies {
	    return [im_companies_csv1]
	}

	projects {
	    return [im_projects_csv1]
	}

	invoices {
	    return [im_invoices_csv1]
	}

	timesheet {
	    return [im_timesheet_csv1]
	}

	default {
	    ad_return_complaint 1 "Invalid file name<br>
            You have specified an invalid file name."
	    return
	}
    }
}



# -----------------------------------------------------------
# Companies CSV Export
# -----------------------------------------------------------


ad_proc im_companies_csv { } {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    return [im_companies_csv1 -status_id 0 -type_id 0 -user_id_from_search 0]
}


ad_proc im_companies_csv1 {
    { -status_id 0 }
    { -type_id 0 }
    { -user_id_from_search 0}
    { -view_name "company_csv" }
} {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    ns_log Notice "im_companies_csv: "
    set current_user_id [ad_maybe_redirect_for_registration]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    if {!$user_is_admin_p} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
	return
    }

    set csv_separator ";"
    
    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    
    set column_headers [list]
    set column_vars [list]
    
    set column_sql "
	select
		column_name,
		column_render_tcl,
		visible_for
	from
		im_view_columns
	where
		view_id=:view_id
		and group_id is null
	order by
		sort_order
    "
    
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # ---------------------------------------------------------------
    # Ket's generate the sql query
    set criteria [list]

    set bind_vars [ns_set create]
    if { $status_id > 0 } {
	ns_set put $bind_vars status_id $status_id
	lappend criteria "c.company_status_id in (
	        select  category_id
	        from    im_categories
	        where   category_id= :status_id
	      UNION
	        select distinct
	                child_id
	        from    im_category_hierarchy
	        where   parent_id = :status_id
        )"
    }

    if { 0 != $user_id_from_search} {
	lappend criteria "
		c.company_id in (
			select object_id_one 
			from acs_rels 
			where object_id_two = :user_id_from_search
		)
	"
    }

    if { $type_id > 0 } {
	    ns_set put $bind_vars type_id $type_id
	    lappend criteria "c.company_type_id in (
		select	category_id
		from	im_categories
		where	category_id= :type_id
	      UNION
		select distinct
			child_id
		from	im_category_hierarchy
		where	parent_id = :type_id
	      )"
    }

    set extra_tables [list]
    set extra_table ""
    if { [llength $extra_tables] > 0 } {
	set extra_table ", [join $extra_tables ","]"
    }

    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set sql "
	select
		c.*,
		c.note as company_note,
		o.*,
		c.primary_contact_id as company_contact_id,
		im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
		im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
		im_name_from_user_id(c.primary_contact_id) as company_contact_name,
		im_email_from_user_id(c.primary_contact_id) as company_contact_email,
	        im_category_from_id(c.company_type_id) as company_type,
	        im_category_from_id(c.company_status_id) as company_status,
	        im_category_from_id(c.annual_revenue_id) as annual_revenue
	from 
		im_offices o,
		im_companies c $extra_table
	where
	        c.main_office_id = o.office_id
		$where_clause
    "

    # ---------------------------------------------------------------
    # Set up colspan to be the number of headers + 1 for the # column
    append table_header_html "<tr>\n"
    set csv_header ""
    foreach col $column_headers {
	
	# Generate a header line for CSV export. Header uses the
	# non-localized text so that it's identical in all languages.
	if {"" != $csv_header} { append csv_header $csv_separator }
	append csv_header "\"[ad_quotehtml $col]\""
	
    }
    
    # ---------------------------------------------------------------
    set ctr 0
    set csv_body ""
    db_foreach projects_info_query $sql {
	
	set csv_line ""
	foreach column_var $column_vars {
	    set ttt ""
	    if {"" != $csv_line} { append csv_line $csv_separator }
	    set cmd "set ttt $column_var"
		eval "$cmd"
	    append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	
	incr ctr
    }

    set string "$csv_header\r\n$csv_body\r\n"
    set string_latin1 [encoding convertto "iso8859-1" $string]
    
    set app_type "application/csv"
#    set app_type "text/plain"
    set charset "latin1"

    # For some reason we have to send out a "hard" HTTP
    # header. ns_return and ns_respond don't seem to convert
    # the content string into the right Latin1 encoding.
    # So we do this manually here...
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $app_type; charset=$charset\r\n"
    util_WriteWithExtraOutputHeaders $all_the_headers

    ns_write $string_latin1

}


# -----------------------------------------------------------
# Projects CSV Export
# -----------------------------------------------------------


ad_proc im_projects_csv { } {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    return [im_projects_csv1 -project_status_id 0 -project_type_id 0 -company_id 0]
}


ad_proc im_projects_csv1 {
    { -view_name "project_csv" }
    { -project_status_id 0 } 
    { -project_type_id 0 } 
    { -company_id 0 } 
} {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    ns_log Notice "im_companies_csv: "
    set current_user_id [ad_maybe_redirect_for_registration]
    set today [lindex [split [ns_localsqltimestamp] " "] 0]

    set view_invoices [im_permission $current_user_id view_invoices]
    set view_projects_all [im_permission $current_user_id view_projects_all]
    set perm [expr $view_invoices && $view_projects_all]
    if {!$view_invoices || !$view_projects_all} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
	return
    }

    set csv_separator ";"
    
    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "
	select view_id 
	from im_views 
	where view_name=:view_name
    " -default 0]
    
    set column_headers [list]
    set column_vars [list]
    
    set column_sql "
	select
		column_name,
		column_render_tcl,
		visible_for
	from
		im_view_columns
	where
		view_id=:view_id
		and group_id is null
	order by
		sort_order
    "
    
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }


    # ---------------------------------------------------------------
    # 5. Generate SQL Query
    # ---------------------------------------------------------------
    
    set criteria [list]
    if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
	lappend criteria "p.project_status_id in (
	select :project_status_id from dual
	UNION
	select child_id
	from im_category_hierarchy
	where parent_id = :project_status_id
    )"
    }

    if { ![empty_string_p $project_type_id] && $project_type_id != 0 } {
	# Select the specified project type and its subtypes
	lappend criteria "p.project_type_id in (
	select :project_type_id from dual
	UNION
	select child_id 
	from im_category_hierarchy
	where parent_id = :project_type_id
    )"
    }
    
    if { ![empty_string_p $company_id] && $company_id != 0 } {
	lappend criteria "p.company_id=:company_id"
    }

    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    

    set create_date ""
    set open_date ""
    set quote_date ""
    set deliver_date ""
    set invoice_date ""
    set close_date ""
    
    set status_from "
	(select project_id, min(audit_date) as when from im_projects_status_audit
	group by project_id) s_create,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_quoting] group by project_id) s_quote,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_open] group by project_id) s_open,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_delivered] group by project_id) s_deliver,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_invoiced] group by project_id) s_invoice,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id in (
		[im_project_status_closed],[im_project_status_canceled],[im_project_status_declined]
	) group by project_id) s_close,
    "

    set status_select "
	s_create.when as create_date,
	s_open.when as open_date,
	s_quote.when as quote_date,
	s_deliver.when as deliver_date,
	s_invoice.when as invoice_date,
	s_close.when as close_date,
    "

    set status_where "
	and p.project_id=s_create.project_id(+)
	and p.project_id=s_quote.project_id(+)
	and p.project_id=s_open.project_id(+)
	and p.project_id=s_deliver.project_id(+)
	and p.project_id=s_invoice.project_id(+)
	and p.project_id=s_close.project_id(+)
    "


    set sql "
	SELECT
		p.*,
	        c.company_name,
		to_char(p.start_date, 'YYYY') as start_year,
		to_char(p.end_date, 'YYYY') as end_year,
		to_char(p.start_date, 'MM') as start_month,
		to_char(p.end_date, 'MM') as end_month,
		tree_level(p.tree_sortkey) as subproject_level,
	        im_name_from_user_id(p.project_lead_id) as lead_name,
		im_email_from_user_id(p.project_lead_id) as lead_email,
		im_project_nr_from_id(p.parent_id) as parent_project_nr,
	        im_category_from_id(p.project_type_id) as project_type,
	        im_category_from_id(p.project_status_id) as project_status,
	        im_category_from_id(p.on_track_status_id) as on_track_status,
	        im_category_from_id(p.billing_type_id) as billing_type,
	        to_char(end_date, 'HH24:MI') as end_date_time
	FROM
		im_projects p,
		im_companies c
	WHERE
		p.company_id = c.company_id
		$where_clause
    "

    # ---------------------------------------------------------------
    append table_header_html "<tr>\n"
    set csv_header ""
    foreach col $column_headers {
	# Generate a header line for CSV export
	if {"" != $csv_header} { append csv_header $csv_separator }
	append csv_header "\"[ad_quotehtml $col]\""
    }
    
    # ---------------------------------------------------------------
    set ctr 0
    set csv_body ""
    db_foreach projects_info_query $sql {
	
	set csv_line ""
	foreach column_var $column_vars {
	    set ttt ""
	    if {"" != $csv_line} { append csv_line $csv_separator }
	    set cmd "set ttt $column_var"
	    eval "$cmd"
	    append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	
	incr ctr
    }

    set string "$csv_header\r\n$csv_body\r\n"
    set string_latin1 [encoding convertto "iso8859-1" $string]
    
    set app_type "application/csv"
#    set app_type "text/plain"
    set charset "latin1"

    # For some reason we have to send out a "hard" HTTP
    # header. ns_return and ns_respond don't seem to convert
    # the content string into the right Latin1 encoding.
    # So we do this manually here...
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $app_type; charset=$charset\r\n"
    util_WriteWithExtraOutputHeaders $all_the_headers

    ns_write $string_latin1

}


# -----------------------------------------------------------
# Timesheet CSV Export
# -----------------------------------------------------------


ad_proc im_timesheet_csv { } {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    return [im_timesheet_csv1]
}


ad_proc im_timesheet_csv1 {
    { -view_name "timesheet_csv" }
    { -project_id 0 } 
    { -company_id 0 } 
} {
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    ns_log Notice "im_timesheet_csv: "
    set current_user_id [ad_maybe_redirect_for_registration]
    set today [lindex [split [ns_localsqltimestamp] " "] 0]

    set view_hours_all [im_permission $current_user_id view_hours_all]
    if {!$view_hours_all} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
	return
    }

    set csv_separator ";"
    
    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "
	select view_id 
	from im_views 
	where view_name=:view_name
    " -default 0]
    
    set column_headers [list]
    set column_vars [list]
    
    set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by
		sort_order
    "
    
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }


    # ---------------------------------------------------------------
    # 5. Generate SQL Query
    # ---------------------------------------------------------------
    
    set criteria [list]
    if { ![empty_string_p $company_id] && $company_id != 0 } {
	lappend criteria "p.company_id = :company_id"
    }
    if { ![empty_string_p $project_id] && $project_id != 0 } {
	lappend criteria "h.project_id = :project_id"
    }

    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set timesheet2_select ""
    set timesheet2_from ""
    set timesheet2_where ""
    if {[db_table_exists im_timesheet_tasks]} {

	set timesheet2_select "
	    t.task_id as timesheet_task_id,
	    m.material_name,
	    m.material_nr,
	    im_category_from_id(t.task_type_id) as timesheet_task_type,
	    im_category_from_id(t.task_status_id) as timesheet_task_status,
	    im_category_from_id(t.uom_id) as timesheet_task_uom,
"
        set timesheet2_from ", im_timesheet_tasks t, im_materials m"
        set timesheet2_where "and h.timesheet_task_id = t.task_id and t.material_id = m.material_id"
    }

    
    set sql "
	SELECT
		$timesheet2_select
		h.hours,
		h.day,
		h.note,
		to_char(h.day, 'YYYY-MM-DD') as day_formatted,
		p.project_id,
		p.project_name,
		p.project_nr,
                im_category_from_id(p.project_type_id) as project_type,
		c.company_id as customer_id,
	        c.company_name as customer_name,
		c.company_path as customer_path,
		u.user_id,
		u.first_names,
		u.last_name,
		u.email
	FROM
		im_hours h,
		im_projects p,
		im_companies c,
		cc_users u
		$timesheet2_from
	WHERE
		h.project_id = p.project_id
		and p.company_id = c.company_id
		and h.user_id = u.user_id
		$timesheet2_where
		$where_clause
    "

    # ---------------------------------------------------------------
    append table_header_html "<tr>\n"
    set csv_header ""
    foreach col $column_headers {
	# Generate a header line for CSV export
	if {"" != $csv_header} { append csv_header $csv_separator }
	append csv_header "\"[ad_quotehtml $col]\""
    }


    # ---------------------------------------------------------------
    # Set variables for Timesheet2
    set timesheet_task_id 0
    set timesheet_material ""
    set timesheet_material ""
    set timesheet_task_type ""
    set timesheet_task_status ""
    set timesheet_uom ""
    set timesheet_task_cost_center ""
    
    # ---------------------------------------------------------------
    set ctr 0
    set csv_body ""
    db_foreach timesheet_info_query $sql {
	
	set csv_line ""
	foreach column_var $column_vars {
	    set ttt ""
	    if {"" != $csv_line} { append csv_line $csv_separator }
	    set cmd "set ttt $column_var"
	    eval "$cmd"
	    append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	
	incr ctr
    }

    set string "$csv_header\r\n$csv_body\r\n"
    set string_latin1 [encoding convertto "iso8859-1" $string]
    
    set app_type "application/csv"
    set charset "latin1"

    # For some reason we have to send out a "hard" HTTP
    # header. ns_return and ns_respond don't seem to convert
    # the content string into the right Latin1 encoding.
    # So we do this manually here...
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $app_type; charset=$charset\r\n"
    util_WriteWithExtraOutputHeaders $all_the_headers

    ns_write $string_latin1

}


# -----------------------------------------------------------
# Invoices CSV Export
# -----------------------------------------------------------


ad_proc im_invoices_csv { } {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    return [im_invoices_csv1 -cost_status_id 0 -cost_type_id 0]
}


ad_proc im_invoices_csv1 {
    { -cost_status_id 0 }
    { -cost_type_id 0 }
    { -customer_id 0 }
    { -provider_id 0 }
    { -view_name "invoice_csv" }
} {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    set current_user_id [ad_get_user_id]
    if {![im_permission $current_user_id view_invoices]} {
	ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
	return
    }
    set csv_separator ";"
    set amp "&"
    set cur_format [im_l10n_sql_currency_format]
    set date_format [im_l10n_sql_date_format]
    set today [lindex [split [ns_localsqltimestamp] " "] 0]


    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    set column_headers [list]
    set column_vars [list]

    set column_sql "
	select
		column_name,
		column_render_tcl,
		visible_for
	from
		im_view_columns
	where
		view_id=:view_id
		and group_id is null
	order by
		sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }


    # ---------------------------------------------------------------
    # Add column_definitions for DynField Vars of the the customer

    set object_type "im_company"
    set attributes_sql "
        select a.attribute_id,
                a.table_name as attribute_table_name,
                tt.id_column as attribute_id_column,
                a.attribute_name,
                a.pretty_name,
                a.datatype,
                case when a.min_n_values = 0 then 'f' else 't' end as required_p,
                a.default_value,
                t.table_name as object_type_table_name,
                t.id_column as object_type_id_column,
                aw.widget,
                aw.parameters,
                im_category_from_id(aw.storage_type_id) as storage_type
        from
                im_dynfield_attributes aa,
                im_dynfield_widgets aw,
                acs_object_types t,
                acs_attributes a left outer join acs_object_type_tables tt on (
                        tt.object_type = :object_type
                        and tt.table_name = a.table_name
                )
        where
                t.object_type = :object_type
                and a.object_type = t.object_type
                and a.attribute_id = aa.acs_attribute_id
                and aa.widget_name = aw.widget_name
                and im_object_permission_p(aa.attribute_id, :current_user_id, 'read') = 't'
        order by
                aa.attribute_id
    "

    set dynfield_select ""
    db_foreach attributes $attributes_sql {

	ns_log Notice "dw-light: im_invoices_csv1: attribute_name=$attribute_name, datatype=$datatype, widget=$widget, storage_type=$storage_type"
	    
	lappend column_headers $pretty_name
	lappend column_vars "\$$attribute_name"
	

	switch $storage_type {

	    value - date - default {

		# Translate company fields to the customers table
		if {[string equal $attribute_table_name "im_companies"]} { set attribute_table_name "c" }
		append dynfield_select "$attribute_table_name.$attribute_name,\n"
		
	    }
	    
	    multimap {
		ad_return_complaint 1 "ToDo: Multimap values not supported yet"
	    }

	}
    }

    # ---------------------------------------------------------------
    # Generate SQL Query
    
    set criteria [list]
    if { ![empty_string_p $cost_status_id] && $cost_status_id > 0 } {
	lappend criteria "i.cost_status_id=:cost_status_id"
    }
    
    if { ![empty_string_p $cost_type_id] && $cost_type_id != 0 } {
	lappend criteria "i.cost_type_id in (
		select distinct	h.child_id
		from	im_category_hierarchy h
		where	(child_id=:cost_type_id or parent_id=:cost_type_id)
	)"
    }
    if { ![empty_string_p $customer_id] && $customer_id != 0 } {
	lappend criteria "i.customer_id=:customer_id"
    }
    if { ![empty_string_p $provider_id] && $provider_id != 0 } {
	lappend criteria "i.provider_id=:provider_id"
    }
    
    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    
    # -----------------------------------------------------------------
    # Define extra SQL for payments
   
    set payment_amount ""
    set payment_currency ""
    
    set extra_select ""
    set extra_from ""
    set extra_where ""
    

    # -----------------------------------------------------------------
    # Main SQL
    
    set sql "
	select
	        i.*,
		$dynfield_select
		(to_date(to_char(i.invoice_date,:date_format),:date_format) 
			+ i.payment_days) as due_date_calculated,
		o.object_type,
		to_char(ci.amount, :cur_format) as invoice_amount,
		ci.currency as invoice_currency,
		ci.paid_amount as payment_amount,
		ci.paid_currency as payment_currency,
		to_char(ci.effective_date, :date_format) as effective_date_formatted,
		to_char(ci.effective_date, 'YYYY') as effective_year,
		to_char(ci.effective_date, 'MM') as effective_month,
		to_char(ci.effective_date, 'DD') as effective_day,
		to_char(ci.amount,:cur_format) as invoice_amount_formatted,
	    	im_email_from_user_id(i.company_contact_id) as company_contact_email,
	      	im_name_from_user_id(i.company_contact_id) as company_contact_name,
	      	im_name_from_user_id(i.payment_method_id) as payment_method,
	      	im_cost_center_name_from_id(ci.cost_center_id) as cost_center,
	      	im_cost_center_code_from_id(ci.cost_center_id) as cost_center_code,
	        c.company_name as customer_name,
	        c.company_path as company_short_name,
		p.company_name as provider_name,
		p.company_path as provider_short_name,
	        im_category_from_id(i.invoice_status_id) as invoice_status,
	        im_category_from_id(i.cost_type_id) as invoice_type,
		to_date(:today, :date_format) 
			- (to_date(to_char(i.invoice_date, :date_format),:date_format) 
			+ i.payment_days) as overdue
		$extra_select
	from
	        im_invoices_active i,
	        im_costs ci,
		acs_objects o,
	        im_companies c,
	        im_companies p
		$extra_from
	where
		i.invoice_id = o.object_id
		and i.invoice_id = ci.cost_id
	 	and i.customer_id=c.company_id
	        and i.provider_id=p.company_id
		$where_clause
		$extra_where
    "

    # ---------------------------------------------------------------
    # Set up colspan to be the number of headers + 1 for the # column

    set csv_header ""
    foreach col $column_headers {
	
	# Generate a header line for CSV export. Header uses the
	# non-localized text so that it's identical in all languages.
	if {"" != $csv_header} { append csv_header $csv_separator }
	append csv_header "\"[ad_quotehtml $col]\""
	
    }
    
    # ---------------------------------------------------------------
    # Format the Result Data
    
    set ctr 0
    set csv_body ""
   
    db_foreach invoices_info_query $sql {

	set read_p [im_cost_center_read_p $cost_center_id $cost_type_id $current_user_id]
	if {!$read_p} { continue }

	set csv_line ""
	foreach column_var $column_vars {
	    set ttt ""
	    if {"" != $csv_line} { append csv_line $csv_separator }
	    set cmd "set ttt $column_var"
		eval "$cmd"
	    append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	
	incr ctr
    }

    set string "$csv_header\r\n$csv_body\r\n"
    set string_latin1 [encoding convertto "iso8859-1" $string]
    
    set app_type "application/csv"
#    set app_type "text/plain"
    set charset "latin1"

    # For some reason we have to send out a "hard" HTTP
    # header. ns_return and ns_respond don't seem to convert
    # the content string into the right Latin1 encoding.
    # So we do this manually here...
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $app_type; charset=$charset\r\n"
    util_WriteWithExtraOutputHeaders $all_the_headers

    ns_write $string_latin1

}
