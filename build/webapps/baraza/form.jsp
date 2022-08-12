<!DOCTYPE html>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}" />
<c:set var="mainPage" value="forms.jsp" scope="page" />
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="org.baraza.web.BWebForms" %>
<%@ page import="org.baraza.xml.BElement" %>

<%
	ServletContext context = getServletContext();
	String dbconfig = "java:/comp/env/jdbc/database";

	String userIP = request.getRemoteAddr();
	String userName = request.getRemoteUser();

	BWebForms form = new BWebForms(dbconfig);
	String formData = form.getWebForm(request.getParameterMap());
	String formTitle = form.getTitle();
%>

<!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
<!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en" class="no-js">
<!--<![endif]-->
<!-- BEGIN HEAD -->
<head>
	<meta charset="utf-8"/>
	<title><%= pageContext.getServletContext().getInitParameter("web_title") %></title>
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta content="width=device-width, initial-scale=1" name="viewport"/>
	<meta content="Open Baraza Framework" name="description"/>
	<meta content="Open Baraza" name="author"/>

	<!-- BEGIN GLOBAL MANDATORY STYLES -->
	<link href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700&subset=all" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/font-awesome/css/font-awesome.min.css"  rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/simple-line-icons/simple-line-icons.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/uniform/css/uniform.default.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/bootstrap-switch/css/bootstrap-switch.min.css" rel="stylesheet" type="text/css"/>
	<!-- END GLOBAL MANDATORY STYLES -->
	<!-- BEGIN PAGE LEVEL PLUGIN STYLES -->
	<link href="./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/fullcalendar/fullcalendar.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/jqvmap/jqvmap/jqvmap.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/morris/morris.css" rel="stylesheet" type="text/css">
	<!-- END PAGE LEVEL PLUGIN STYLES -->
	<!-- BEGIN PAGE STYLES -->
	<link href="./assets/admin/pages/css/tasks.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/clockface/css/clockface.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-datepicker/css/bootstrap-datepicker3.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-timepicker/css/bootstrap-timepicker.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-colorpicker/css/colorpicker.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-datetimepicker/css/bootstrap-datetimepicker.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/jquery-tags-input/jquery.tagsinput.css" rel="stylesheet" type="text/css"/>
    <link href="./assets/global/plugins/select2/select2.css" rel="stylesheet" type="text/css" />
    <link href="./assets/global/plugins/jquery-multi-select/css/multi-select.css" rel="stylesheet" type="text/css" />
    <link href="./assets/global/plugins/fullcalendar/fullcalendar.min.css" rel="stylesheet"/>
    <link href="./assets/global/plugins/bootstrap-toastr/toastr.min.css" rel="stylesheet" type="text/css"/>
    <link href="./assets/global/plugins/bootstrap-fileinput/bootstrap-fileinput.css" rel="stylesheet" type="text/css"/>
    <link href="./assets/admin/pages/css/profile.css" rel="stylesheet" type="text/css"/>

	<link href="./assets/global/plugins/jstree/dist/themes/default/style.min.css" rel="stylesheet" type="text/css"/>


    <!-- CSS to style the file input field as button and adjust the Bootstrap progress bars -->
    <link href="./assets/global/plugins/jquery-file-upload/css/jquery.fileupload.css" rel="stylesheet">

	<!-- END PAGE STYLES -->
	<!-- BEGIN THEME STYLES -->
	<!-- DOC: To use 'rounded corners' style just load 'components-rounded.css' stylesheet instead of 'components.css' in the below style tag -->
    <script >console.info("Default Design") </script>
    <link href="./assets/global/css/components-rounded.css" id="style_components" rel="stylesheet" type="text/css"/>
    <link href="./assets/global/css/plugins.css" rel="stylesheet" type="text/css"/>

	<link href="./assets/admin/layout4/css/layout.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/themes/light.css" rel="stylesheet" type="text/css" id="style_color"/>

	<!-- END THEME STYLES -->
	<link rel="shortcut icon" href="./assets/logos/favicon.png"/>

	<link href="./assets/global/plugins/jquery-ui/jquery-ui-1.10.3.custom.min.css" rel="stylesheet" type="text/css" media="screen" />
    <link href="./assets/jqgrid/css/ui.jqgrid.css" rel="stylesheet" type="text/css" media="screen" />
    <link href="./assets/admin/layout4/css/custom.css" rel="stylesheet" type="text/css"/>

	<!-- jsgrid css -->
    <link type="text/css" rel="stylesheet" href="./assets/jsgrid/jsgrid.min.css" />
    <link type="text/css" rel="stylesheet" href="./assets/jsgrid/jsgrid-theme.min.css" />

</head>
<!-- END HEAD -->
<!-- BEGIN BODY -->
<!-- DOC: Apply "page-header-fixed-mobile" and "page-footer-fixed-mobile" class to body element to force fixed header or footer in mobile devices -->
<!-- DOC: Apply "page-sidebar-closed" class to the body and "page-sidebar-menu-closed" class to the sidebar menu element to hide the sidebar by default -->
<!-- DOC: Apply "page-sidebar-hide" class to the body to make the sidebar completely hidden on toggle -->
<!-- DOC: Apply "page-sidebar-closed-hide-logo" class to the body element to make the logo hidden on sidebar toggle -->
<!-- DOC: Apply "page-sidebar-hide" class to body element to completely hide the sidebar on sidebar toggle -->
<!-- DOC: Apply "page-sidebar-fixed" class to have fixed sidebar -->
<!-- DOC: Apply "page-footer-fixed" class to the body element to have fixed footer -->
<!-- DOC: Apply "page-sidebar-reversed" class to put the sidebar on the right side -->
<!-- DOC: Apply "page-full-width" class to the body element to have full width page without the sidebar menu -->
<body class="page-header-fixed page-sidebar-closed-hide-logo page-sidebar-closed-hide-logo page-footer-fixed">

<!-- BEGIN HEADER -->
<div class="page-header navbar navbar-fixed-top">
	<!-- BEGIN HEADER INNER -->
	<div class="page-header-inner">
		<!-- BEGIN LOGO -->
		<div class="page-logo">
			<a href="index.jsp">
			<img src="./assets/logos/logo_header.png" alt="logo" style="margin: 20px 10px 0 10px; width: 107px;" class="logo-default"/>
			</a>
		</div>
		<!-- END LOGO -->

		<!-- BEGIN PAGE TOP -->
		<div class="page-top">

			<!-- BEGIN TOP NAVIGATION MENU -->
			<div class="top-menu">
				<ul class="nav navbar-nav pull-right">
					<!-- BEGIN USER LOGIN DROPDOWN -->
					<!-- END USER LOGIN DROPDOWN -->
				</ul>
			</div>
			<!-- END TOP NAVIGATION MENU -->
		</div>
		<!-- END PAGE TOP -->
	</div>
	<!-- END HEADER INNER -->
</div>

<!-- END HEADER -->

<div class="clearfix"></div>

<!-- BEGIN CONTAINER -->
<div class="page-container">
	<div class="row">
		<div class="col-md-12">
			<!-- BEGIN Portlet PORTLET-->
			<div class="portlet light">
				<div class="portlet-title">
					<div class="caption">
						<i class="icon-speech"></i>
						<span class="caption-subject bold uppercase"> <%= formTitle %></span>
					</div>
					<div class="actions">
					  <% if(form.canSave()) { %>
						<a href="javascript:;" class="btn btn-circle btn-default" onclick="getFormValues();" id="formvalues">
						<i class="fa fa-pencil"></i> Save </a>
						<a href="javascript:;" class="btn btn-circle btn-default" onclick="getFormSumbit();" id="formsumbit">
						<i class="fa fa-plus"></i> Submit </a>
						<a href="javascript:;" class="btn btn-circle btn-default btn-icon-only fullscreen"></a>
					  <% } %>
					</div>
				</div>
				<div class="portlet-body">
					<div class="scroller" style="height:575px" data-rail-visible="1" data-rail-color="yellow" data-handle-color="#a1b2bd">
						<section><div id="resp_msg"></div></section>
						<form id='barazaForm' name='barazaForm' method='post' action='form.jsp'>
							<%= form.getFormTabs() %>
							<%= formData %>
						</form>
					</div>
				</div>
			</div>
			<!-- END Portlet PORTLET-->
		</div>
	</div>
</div>
<!-- END CONTAINER -->


<!-- BEGIN FOOTER -->
<div class="page-footer">
	<div class="page-footer-inner">
		2017 &copy; Open Baraza. <a href="http://dewcis.com">Dew Cis Solutions Ltd.</a> All Rights Reserved
	</div>
	<div class="scroll-to-top">
		<i class="icon-arrow-up"></i>
	</div>
</div>

<!-- END FOOTER -->
<!-- BEGIN JAVASCRIPTS(Load javascripts at bottom, this will reduce page load time) -->
<!-- BEGIN CORE PLUGINS -->
<!--[if lt IE 9]>
<script src="./assets/global/plugins/respond.min.js"></script>
<script src="./assets/global/plugins/excanvas.min.js"></script>
<![endif]-->
<script src="./assets/global/plugins/jquery.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-migrate.min.js" type="text/javascript"></script>
<!-- IMPORTANT! Load jquery-ui.min.js before bootstrap.min.js to fix bootstrap tooltip conflict with jquery ui tooltip -->
<script src="./assets/global/plugins/jquery-ui/jquery-ui.min.js" type="text/javascript"></script>
<!--<script src="./jquery-ui-1.11.4.custom/jquery-ui.min.js"  type="text/javascript"></script>-->
<script src="./assets/global/plugins/bootstrap/js/bootstrap.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-hover-dropdown/bootstrap-hover-dropdown.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-slimscroll/jquery.slimscroll.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.blockui.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.cokie.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/uniform/jquery.uniform.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-switch/js/bootstrap-switch.min.js" type="text/javascript"></script>
<!-- END CORE PLUGINS -->
<!-- BEGIN PAGE LEVEL PLUGINS -->
<script src="./assets/global/plugins/jqvmap/jqvmap/jquery.vmap.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.russia.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.world.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.europe.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.germany.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.usa.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/data/jquery.vmap.sampledata.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-datetimepicker/js/bootstrap-datetimepicker.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-datepicker/js/bootstrap-datepicker.min.js" type="text/javascript" ></script>
<script src="./assets/global/plugins/ckeditor/ckeditor.js" type="text/javascript" ></script>

<script src="./assets/global/plugins/jquery-inputmask/jquery.inputmask.bundle.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/select2/select2.min.js" type="text/javascript"></script>


<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/morris/morris.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/morris/raphael-min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.sparkline.min.js" type="text/javascript"></script>
<!-- END PAGE LEVEL PLUGINS -->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/jquery.ui.widget.js"></script>
<!-- The Load Image plugin is included for the preview images and image resizing functionality -->
<!--<script src="//blueimp.github.io/JavaScript-Load-Image/js/load-image.all.min.js"></script>-->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/load-image.min.js"></script>
<!-- The Canvas to Blob plugin is included for image resizing functionality -->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/canvas-to-blob.min.js"></script>
<!-- The Iframe Transport is required for browsers without support for XHR file uploads -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.iframe-transport.js"></script>
<!-- The basic File Upload plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload.js"></script>
<!-- The File Upload processing plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-process.js"></script>
<!-- The File Upload image preview & resize plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-image.js"></script>
<!-- The File Upload audio preview plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-audio.js"></script>
<!-- The File Upload video preview plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-video.js"></script>
<!-- The File Upload validation plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-validate.js"></script>

<!-- BEGIN PAGE LEVEL SCRIPTS -->
<script src="./assets/global/plugins/bootstrap-fileinput/bootstrap-fileinput.js" type="text/javascript"></script>
<script src="./assets/global/scripts/metronic.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/layout.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/demo.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/index3.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/tasks.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/components-pickers.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.multi-select.js" type="text/javascript" ></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.quicksearch.js" type="text/javascript"></script>
<script src="./assets/global/plugins/clockface/js/clockface.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jstree/dist/jstree.min.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/ui-tree.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-toastr/toastr.min.js"></script>

<!-- END PAGE LEVEL SCRIPTS -->

<script type="text/javascript" src="./assets/jqgrid/js/i18n/grid.locale-en.js"></script>
<script type="text/javascript" src="./assets/jqgrid/js/jquery.jqGrid.min.js"></script>

<!-- calendar-->
<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/moment.min.js"></script>
<script src="./assets/global/plugins/fullcalendar/fullcalendar.min.js"></script>

<!-- jsgrid for sub form editing-->
<script src="./assets/jsgrid/jsgrid.min.js"></script>

<script type="text/javascript">
    jQuery(document).ready(function() {
        Metronic.init(); // init metronic core componets
        Layout.init(); // init layout

        $('.date-picker').datepicker({
            autoclose: true
        });

		UITree.init();

		$('.clockface').clockface({
            format: 'hh:mm a',
            trigger: 'manual'
        });

        $('.clockface-toggle').click(function (e) {
            e.stopPropagation();
            var target = $(this).attr('data-target');
            $('#' + target ).clockface('toggle');
        });

		$('.select2me').select2({
            placeholder: "Select an option",
            allowClear: true
        });
    });

    var MyDateField = function(config) {
        jsGrid.Field.call(this, config);
    };

    MyDateField.prototype = new jsGrid.Field({
        sorter: function(date1, date2) {
            return new Date(date1) - new Date(date2);
        },

        itemTemplate: function(value) {
            return new Date(value).toDateString();
        },

        insertTemplate: function(value) {
            return this._insertPicker = $("<input>").datepicker({ defaultDate: new Date() });
        },

        editTemplate: function(value) {
            return this._editPicker = $("<input>").datepicker().datepicker("setDate", new Date(value));
        },

        insertValue: function() {
            return this._insertPicker.datepicker("getDate").toISOString();
        },

        editValue: function() {
            return this._editPicker.datepicker("getDate").toISOString();
        }
    });

    jsGrid.fields.myDateField = MyDateField;

	<%= form.printSubForm() %>

	function getFormValues() {
        var str = '';
		var jsonForm = {};
        var elem = document.getElementById('barazaForm').elements;
        for(var i = 0; i < elem.length; i++) {
			if(!(elem[i].name == null || elem[i].name == "", elem[i].value == null || elem[i].value == "")) {
				jsonForm[elem[i].name] = elem[i].value;
			}
        }

		for	(i = 0; i < db_list.length; i++) {
			jsonForm[db_list[i]] = eval(db_list[i]);
		}

		$.ajax({
			type: "POST",
			url: "ajaxupdate?fnct=formupdate&entry_form_id=" + <%=form.getEntryFormId()%>,
			data: "json=" + JSON.stringify(jsonForm),
			dataType: "json",
			success: function(data){
console.log("Success: ");
console.log(data);
			},
			failure: function(errMsg) {
console.log("Error: ");
console.log(data);
			}
		});
    }

	function getFormSumbit() {
		var repost = true;
        var str = '';
		var jsonForm = {};
        var elem = document.getElementById('barazaForm').elements;
        for(var i = 0; i < elem.length; i++) {
			if(!(elem[i].name == null || elem[i].name == "", elem[i].value == null || elem[i].value == "")) {
				jsonForm[elem[i].name] = elem[i].value;
			}
        }

		for	(i = 0; i < db_list.length; i++) {
			jsonForm[db_list[i]] = eval(db_list[i]);
		}

		$.ajax({
			type: "POST",
			url: "ajaxupdate?fnct=formsubmit&entry_form_id=" + <%=form.getEntryFormId()%>,
			data: "json=" + JSON.stringify(jsonForm),
			dataType: "json",
			success: function(data){
console.log("Success: ");
console.log(data);
				$("#resp_msg").html(data.message);

				$("#formsumbit").addClass("disabled");
				$("#formvalues").addClass("disabled");
			},
			failure: function(errMsg) {
console.log("Error: ");
console.log(data);
				$("#resp_msg").html(data.message);
			}
		});
	}

</script>

</body>
<!-- END BODY -->
</html>

<% 	form.close(); %>
