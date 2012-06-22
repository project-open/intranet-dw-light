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

    # Convert vars into hash
    set vars_hash [array get {}]
    set pairs [split $query "&"]
    foreach pair $pairs {
	set var_val [split $pair "="]
	set var [lindex $var_val 0]
	set val [lindex $var_val 1]
	set var_hash($var) $val
    }
    set vars [array get var_hash]

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
	ad_script_abort
    }

    ns_log Notice "im_dw_light_handler: url=$url, body=$file_body, ext=$file_ext, query=$query, vars=$vars"

    switch $file_body {
	companies { return [im_companies_csv1 -vars $vars] }
	projects { return [im_projects_csv1 -vars $vars] }
	invoices { return [im_invoices_csv1 -vars $vars] }
	timesheet { return [im_timesheet_csv1 -vars $vars] }
	users { return [im_users_csv1 -vars $vars] }
	default {
	    ad_return_complaint 1 "Invalid file name<br>
            You have specified an invalid file name."
	    ad_script_abort
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
    { -company_status_id 0 }
    { -company_type_id 0 }
    { -user_id_from_search 0}
    { -view_name "company_csv" }
    { -vars "" }
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

    array set var_hash $vars
    if {[info exists var_hash(company_status_id)]} { set company_status_id $var_hash(company_status_id) }
    if {[info exists var_hash(company_type_id)]} { set company_type_id $var_hash(company_type_id) }
    if {[info exists var_hash(user_id_from_search)]} { set user_id_from_search $var_hash(user_id_from_search) }
    if {[info exists var_hash(view_name)]} { set view_name $var_hash(view_name) }

    set csv_separator ";"
    
    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    
    # ad_return_complaint 1 $view_id

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

    # Add DynField variables to the view
    # The function returns two lists, for "headers" and "vars"
    set lol [im_dynfield::append_attributes_to_im_view -object_type "im_company"]
    set column_headers [concat $column_headers [lindex $lol 0]]
    set column_vars [concat $column_vars [lindex $lol 1]]
    set derefs [lindex $lol 2]

    # ---------------------------------------------------------------
    # Let's generate the sql query
    set criteria [list]

    set bind_vars [ns_set create]
    if { $company_status_id > 0 } {
	ns_set put $bind_vars company_status_id $company_status_id
	lappend criteria "c.company_status_id in ([join [im_sub_categories $company_status_id] ","])"
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

    if { $company_type_id > 0 } {
	ns_set put $bind_vars company_type_id $company_type_id
	lappend criteria "c.company_type_id in ([join [im_sub_categories $company_type_id] ","])"
    }

    set extra_tables [list]
    set extra_table ""
    if { [llength $extra_tables] > 0 } {
	set extra_table ", [join $extra_tables ","]"
    }

    set where_clause [join $criteria " and\n	    "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set sql "
	select
		c.*,
		[join $derefs "\n"]
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
            if [catch {
		set ttt ""
		if {"" != $csv_line} { append csv_line $csv_separator }
		set cmd "set ttt $column_var"
		eval "$cmd"
		append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
            } errmsg] {
                ns_log ERROR "Error during exporting companies: variable $column_var not defined."
            }
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	incr ctr
    }


    # !! This code only works with aolserver4.0. !!
    # The older server (aolserver3.3oacs) doesn't handle
    # encodings correctly.
    #
    set string "$csv_header\r\n$csv_body\r\n"

    # TCL Encoding, application type and character set - iso8859-1 or UTF-8?
    set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
    set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
    set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

    if {"utf-8" == $tcl_encoding} { 
	set string_latin1 $string
    } else { 
	set string_latin1 [encoding convertto $tcl_encoding $string]
    }

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
    { -vars "" }
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

    array set var_hash $vars
    if {[info exists var_hash(view_name)]} { set view_name $var_hash(view_name) }
    if {[info exists var_hash(project_status_id)]} { set project_status_id $var_hash(project_status_id) }
    if {[info exists var_hash(project_type_id)]} { set project_type_id $var_hash(project_type_id) }
    if {[info exists var_hash(company_id)]} { set company_id $var_hash(company_id) }

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
	    lappend column_headers $column_name
	    lappend column_vars $column_render_tcl
	}
    }


    # Add DynField variables to the view
    # The function returns two lists, for "headers" and "vars"
    set project_lol [im_dynfield::append_attributes_to_im_view -object_type "im_project"]
    set project_column_headers	[lindex $project_lol 0]
    set project_column_vars	[lindex $project_lol 1]
    set project_derefs		[lindex $project_lol 2]

    set task_lol [im_dynfield::append_attributes_to_im_view -object_type "im_timesheet_task"]
    set task_column_headers	[lindex $task_lol 0]
    set task_column_vars	[lindex $task_lol 1]
    set task_derefs		[lindex $task_lol 2]

    set column_headers [concat $column_headers $project_column_headers $task_column_headers]
    set column_vars [concat $column_vars $project_column_vars $task_column_vars]
    set derefs [concat $project_derefs $task_derefs]

    # ---------------------------------------------------------------
    # 5. Generate SQL Query
    # ---------------------------------------------------------------
    
    set criteria [list]
    if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
	lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
    }

    if { ![empty_string_p $project_type_id] && $project_type_id != 0 } {
	# Select the specified project type and its subtypes
	lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
    }
    
    if { ![empty_string_p $company_id] && $company_id != 0 } {
	lappend criteria "p.company_id=:company_id"
    }

    set where_clause [join $criteria " and\n	    "]
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


    set im_gantt_projects_sql ","
    if {[im_table_exists im_gantt_projects]} {
	set im_gantt_projects_sql "LEFT OUTER JOIN im_gantt_projects gp ON (p.project_id = gp.project_id),"
    }

    set sql "
	SELECT
		p.*,
		[join $derefs "\n"]
		c.company_name,
		im_name_from_user_id(c.manager_id) as keyacc_name,
		im_email_from_user_id(c.manager_id) as keyacc_email,
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
		im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
		$im_gantt_projects_sql
		(select	company_id,
			company_name,
			manager_id
		from	im_companies) c
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

	# compatibility with older versions
	set project_lead $lead_name
	
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

    # TCL Encoding, application type and character set - iso8859-1 or UTF-8?
    set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
    set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
    set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

    if {"utf-8" == $tcl_encoding} { 
	set string_latin1 $string
    } else {
	set string_latin1 [encoding convertto $tcl_encoding $string] 
    }

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
    { -vars "" }
    { -view_name "timesheet_csv" }
    { -project_id 0 } 
    { -company_id 0 } 
    { -start_date "" }
    { -end_date "" }
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

    array set var_hash $vars
    if {[info exists var_hash(company_id)]} { set company_id $var_hash(company_id) }
    if {[info exists var_hash(project_id)]} { set project_id $var_hash(project_id) }
    if {[info exists var_hash(view_name)]} { set view_name $var_hash(view_name) }
    if {[info exists var_hash(start_date)]} { set start_date $var_hash(start_date) }
    if {[info exists var_hash(end_date)]} { set end_date $var_hash(end_date) }

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
    if { ![empty_string_p $start_date]} {
	lappend criteria "h.day > to_timestamp(:start_date, 'YYYY-MM-DD')"
    }
    if { ![empty_string_p $end_date]} {
	lappend criteria "h.day > to_timestamp(:end_date, 'YYYY-MM-DD')"
    }

    set where_clause [join $criteria " and\n	    "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set sql "
	SELECT
		h.hours,
		h.day,
		h.note as hours_note,
		to_char(h.day, 'YYYY-MM-DD') as day_formatted,
		u.*,
		e.*,
		supervisor.email as supervisor_email,
		im_name_from_user_id(supervisor.party_id) as supervisor_name,
		cc.*,
		p.project_id,
		p.project_name,
		p.project_nr,
		parent_p.project_name as parent_project_name,
		parent_p.project_nr as parent_project_nr,
		top_p.project_name as top_project_name,
		top_p.project_nr as top_project_nr,
		im_category_from_id(p.project_type_id) as project_type,
		im_category_from_id(p.project_type_id) as timesheet_task_type,
		im_category_from_id(p.project_status_id) as timesheet_task_status,
		im_category_from_id(t.uom_id) as timesheet_task_uom,
		t.task_id as timesheet_task_id,
		m.material_name,
		m.material_nr,
		c.company_id as customer_id,
		c.company_name as customer_name,
		c.company_path as customer_path
	FROM
		im_projects p
                LEFT OUTER JOIN im_projects parent_p ON (p.parent_id = parent_p.project_id)
		LEFT OUTER JOIN im_timesheet_tasks t on (p.project_id = t.task_id)
		LEFT OUTER JOIN im_materials m ON (t.material_id = m.material_id),
		im_hours h,
		im_companies c,
                im_projects top_p,
		cc_users u
		LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		LEFT OUTER JOIN im_cost_centers cc ON (e.department_id = cc.cost_center_id)
		LEFT OUTER JOIN parties supervisor ON (e.supervisor_id = supervisor.party_id)
	WHERE
		h.project_id = p.project_id
		and p.company_id = c.company_id
		and h.user_id = u.user_id
		and top_p.tree_sortkey = tree_ancestor_key(p.tree_sortkey, 1)
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

    # TCL Encoding, application type and character set - iso8859-1 or UTF-8?
    set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
    set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
    set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

    if {"utf-8" == $tcl_encoding} { 
	set string_latin1 $string
    } else { 
	set string_latin1 [encoding convertto $tcl_encoding $string]
    }

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
    { -vars "" }
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

    array set var_hash $vars
    if {[info exists var_hash(customer_id)]} { set customer_id $var_hash(customer_id) }
    if {[info exists var_hash(provider_id)]} { set provider_id $var_hash(provider_id) }
    if {[info exists var_hash(cost_status_id)]} { set cost_status_id $var_hash(cost_status_id) }
    if {[info exists var_hash(cost_type_id)]} { set cost_type_id $var_hash(cost_type_id) }
    if {[info exists var_hash(view_name)]} { set view_name $var_hash(view_name) }

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


    # Add DynField variables to the view
    # The function returns two lists, for "headers" and "vars"
    set lol [im_dynfield::append_attributes_to_im_view -object_type "im_cost"]
    set column_headers [concat $column_headers [lindex $lol 0]]
    set column_vars [concat $column_vars [lindex $lol 1]]


    # Add DynField variables to the view
    # The function returns two lists, for "headers" and "vars"
    set lol [im_dynfield::append_attributes_to_im_view -object_type "im_company" -table_prefix "c."]
    set column_headers [concat $column_headers [lindex $lol 0]]
    set column_vars [concat $column_vars [lindex $lol 1]]
    set company_dynfield_select [join [lindex $lol 2] " "]

    # ---------------------------------------------------------------
    # Generate SQL Query
    
    set criteria [list]
    if { ![empty_string_p $cost_status_id] && $cost_status_id > 0 } {
	lappend criteria "i.cost_status_id=:cost_status_id"
    }
    
    if { ![empty_string_p $cost_type_id] && $cost_type_id != 0 } {
	lappend criteria "i.cost_type_id in ([join [im_sub_categories $cost_type_id] ","])"
    }
    if { ![empty_string_p $customer_id] && $customer_id != 0 } {
	lappend criteria "i.customer_id=:customer_id"
    }
    if { ![empty_string_p $provider_id] && $provider_id != 0 } {
	lappend criteria "i.provider_id=:provider_id"
    }
    
    set where_clause [join $criteria " and\n	    "]
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
		$company_dynfield_select
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

    # TCL Encoding, application type and character set - iso8859-1 or UTF-8?
    set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
    set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
    set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

    if {"utf-8" == $tcl_encoding} { 
	set string_latin1 $string 
    } else { 
	set string_latin1 [encoding convertto $tcl_encoding $string]
    }

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
# Users CSV Export
# -----------------------------------------------------------


ad_proc im_users_csv1 {
    { -member_state "approved" }
    { -view_name "user_csv" }
    { -vars "" }
} {  
    Returns a "broad" CSV file particularly designed to be
    Pivot-Table friendly.
} {
    set current_user_id [ad_get_user_id]
    if {![im_permission $current_user_id view_users]} {
	ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
	return
    }
    set csv_separator ";"
    set amp "&"
    set cur_format [im_l10n_sql_currency_format]
    set date_format [im_l10n_sql_date_format]
    set today [lindex [split [ns_localsqltimestamp] " "] 0]

    array set var_hash $vars
    if {[info exists var_hash(view_name)]} { set view_name $var_hash(view_name) }
    if {[info exists var_hash(member_state)]} { set member_state $var_hash(member_state) }


    # ---------------------------------------------------------------
    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    set column_headers [list]
    set column_vars [list]

    set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # Add DynField variables to the view
    # The function returns two lists, for "headers" and "vars"
    set lol [im_dynfield::append_attributes_to_im_view -object_type "person"]
    set column_headers [concat $column_headers [lindex $lol 0]]
    set column_vars [concat $column_vars [lindex $lol 1]]

    # ---------------------------------------------------------------
    # Generate SQL Query
    
    set criteria [list]
    if {"" !=  $member_state} {
	lappend criteria "member_state = :member_state"
    }
    
    set where_clause [join $criteria " and\n	    "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    
    set extra_select ""
    set extra_from ""
    

    # -----------------------------------------------------------------
    # Main SQL

    set sql "
	SELECT 
		pa.*,
		pe.*,
		u.user_id,
		u.username,
		u.screen_name,
		mr.member_state,
		uc.*,
		e.*,
		im_cost_center_name_from_id(e.department_id) as department,
		im_name_from_user_id(e.supervisor_id) as supervisor_name,
		im_profiles_from_user_id(u.user_id) as profiles
		$extra_select
	FROM
		parties pa,
		persons pe,
		users u
		LEFT OUTER JOIN users_contact uc ON (u.user_id = uc.user_id)
		LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id),
		group_member_map m,
		membership_rels mr
		$extra_from
	WHERE
		pa.party_id = pe.person_id
		AND pe.person_id = u.user_id
		AND u.user_id = m.member_id
		AND m.group_id = acs__magic_object_id('registered_users')
		AND m.rel_id = mr.rel_id
		AND m.container_id = m.group_id
		AND m.rel_type = 'membership_rel'
		$where_clause
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
   
    db_foreach users_info_query $sql {

	set csv_line ""
	foreach column_var $column_vars {
	    set ttt ""
	    if {"" != $csv_line} { append csv_line $csv_separator }
	    set cmd "set ttt $column_var"
	    catch { eval "$cmd" }
	    append csv_line "\"[im_csv_duplicate_double_quotes $ttt]\""
	}
	append csv_line "\r\n"
	append csv_body $csv_line
	
	incr ctr
    }

    set string "$csv_header\r\n$csv_body\r\n"

    # TCL Encoding, application type and character set - iso8859-1 or UTF-8?
    set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
    set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
    set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

    if {"utf-8" == $tcl_encoding} { 
	set string_latin1 $string 
    } else {
	set string_latin1 [encoding convertto $tcl_encoding $string]
    }

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
