<!DOCTYPE html>
<%@ page import="org.baraza.web.*" %>
<%@ page import="org.baraza.xml.BElement" %>

<%
	ServletContext context = getServletContext();
	String dbconfig = "java:/comp/env/jdbc/database";
	String xmlcnf = "fidelity.xml";
	if(request.getParameter("logoff") == null) {
		session.setAttribute("xmlcnf", xmlcnf);
	} else {
		session.removeAttribute("xmlcnf");
		session.invalidate();
  	}

	String ps = System.getProperty("file.separator");
	String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
	String reportPath = context.getRealPath("reports") + ps;

	String userIP = request.getRemoteAddr();
	String userName = request.getRemoteUser();

	BWeb web = new BWeb(dbconfig, xmlfile);
	web.setUser(userIP, userName);
	web.init(request);
	web.setMainPage("index.jsp");

	String entryformid = null;
	String action = request.getParameter("action");
	String value = request.getParameter("value");
	String post = request.getParameter("post");
	String process = request.getParameter("process");
	String actionprocess = request.getParameter("actionprocess");
	if(actionprocess != null) process = "actionProcess";
	String reportexport = request.getParameter("reportexport");
	String excelexport = request.getParameter("excelexport");

	String fieldTitles = web.getFieldTitles();
	String auditTable = null;

	String opResult = null;
	if(process != null) {
		if(process.equals("actionProcess")) {
			opResult = web.setOperation(actionprocess, request);
		} else if(process.equals("FormAction")) {
			String actionKey = request.getParameter("actionkey");
			opResult = web.setOperation(actionKey, request);
		} else if(process.equals("Update")) {
			web.updateForm(request);
		} else if(process.equals("Delete")) {
			web.deleteForm(request);
		} else if(process.equals("Submit")) {
			web.submitGrid(request);
		} else if(process.equals("Check All")) {
			web.setSelectAll();
		} else if(process.equals("Audit")) {
			auditTable = web.getAudit();
		}
	}

	if(excelexport != null) reportexport = excelexport;
	if(reportexport != null) {
		out.println("	<script>");
		out.println("		window.open('show_report?report=" + reportexport + "');");
		out.println("	</script>");
	}
%>

<!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
<!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en" class="no-js">
<!--<![endif]-->
<!-- BEGIN HEAD -->
<head>
	<meta charset="utf-8"/>
	<title>Fidelity</title>
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta content="width=device-width, initial-scale=1" name="viewport"/>
	<meta content="" name="description"/>
	<meta content="" name="author"/>
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


	<!-- END PAGE STYLES -->
	<!-- BEGIN THEME STYLES -->
	<!-- DOC: To use 'rounded corners' style just load 'components-rounded.css' stylesheet instead of 'components.css' in the below style tag -->
	<link href="./assets/global/css/components-rounded.css" id="style_components" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/css/plugins.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/layout.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/themes/light.css" rel="stylesheet" type="text/css" id="style_color"/>
	
	<!-- END THEME STYLES -->
	<link rel="shortcut icon" href="favicon.ico"/>

	<link rel="stylesheet" type="text/css" media="screen" href="assets/global/plugins/jquery-ui/jquery-ui-1.10.3.custom.min.css" />
    <link href="./jquery-ui-1.11.4.custom/jquery-ui.theme.min.css" rel="search" type="text/css" />
    <link href="assets/jqgrid/css/ui.jqgrid.css" rel="stylesheet" type="text/css" media="screen"  />
    <link href="./assets/admin/layout4/css/custom.css" rel="stylesheet" type="text/css"/>
     
    
	<script type="text/javascript" src="./assets/chat/org/cometd.js"></script>
	<script type="text/javascript" src="./assets/chat/cometd/AckExtension.js"></script>
	<script type="text/javascript" src="./assets/chat/cometd/ReloadExtension.js"></script>
	<script type="text/javascript" src="./assets/chat/jquery/jquery.cookie.js"></script>
	<script type="text/javascript" src="./assets/chat/jquery/jquery.cometd.js"></script>
	<script type="text/javascript" src="./assets/chat/jquery/jquery.cometd-reload.js"></script>
	<script type="text/javascript" src="./assets/chat/chat.window.js"></script>
	<script type="text/javascript" src="./assets/chat/comet.chat.js"></script>

	<link type="text/css" rel="stylesheet" href="./assets/chat/comet.chat.css"/>

<script type="text/javascript">
		 var chat = $.noConflict(true); 
	var userName = '<%= web.getOrgName() %>';
	chat(document).ready(function(){ 
	
		chat.cometChat.onLoad({memberListContainerID:'members'});
		join(userName);
		 
		 if(userName != 'Dewcis'){
		
		var humanChat = document.getElementById('human_chat');
        humanChat.onclick = createWindow(userName,'Dewcis') ;
 
        
 }
		
	});
	</script>
	</head>


<body class="page-header-fixed page-sidebar-closed-hide-logo page-sidebar-closed-hide-logo page-footer-fixed">




<!-- BEGIN HEADER -->
<div class="page-header navbar navbar-fixed-top">
	<!-- BEGIN HEADER INNER -->
	<div class="page-header-inner">
		<!-- BEGIN LOGO -->
		<div class="page-logo">
			<a href="index.html">
			<img src="./assets/admin/layout4/img/logo-light.png" alt="logo" class="logo-default"/>
			</a>
			<div class="menu-toggler sidebar-toggler">
				<!-- DOC: Remove the above "hide" to enable the sidebar toggler button on header -->
			</div>
		</div>
		<!-- END LOGO -->
		<!-- BEGIN RESPONSIVE MENU TOGGLER -->
		<a href="javascript:;" class="menu-toggler responsive-toggler" data-toggle="collapse" data-target=".navbar-collapse">
		</a>
		<!-- END RESPONSIVE MENU TOGGLER -->

		<!-- BEGIN PAGE TOP -->
		<div class="page-top">

			<!-- BEGIN TOP NAVIGATION MENU -->
			<div class="top-menu">
				<ul class="nav navbar-nav pull-right">
					<!-- BEGIN USER LOGIN DROPDOWN -->
					<!-- DOC: Apply "dropdown-dark" class after below "dropdown-extended" to change the dropdown styte -->
					<li class="dropdown dropdown-user dropdown-dark">
						<a href="javascript:;" class="dropdown-toggle" data-toggle="dropdown" data-hover="dropdown" data-close-others="true">
						<span class="username username-hide-on-mobile">
						<%= web.getOrgName() %> | <%= web.getEntityName() %>  </span>
						<!-- DOC: Do not remove below empty space(&nbsp;) as its purposely used -->
						<img alt="" class="img-circle" src="./assets/admin/layout4/img/avatar.png"/>
						</a>
						<ul class="dropdown-menu dropdown-menu-default">
							<li>
								<a href="extra_profile.html">
								<i class="icon-user"></i> My Profile </a>
							</li>
							
							<li>
								<a href="index.jsp" id= "human_chat"> 
								<i class="icon-user"></i> Human Chat </a>
							</li>
							
							<li>
								<a href="page_calendar.html">
								<i class="icon-calendar"></i> My Calendar </a>
							</li>
							<li>
								<a href="page_todo.html">
								<i class="icon-rocket"></i> My Tasks <span class="badge badge-success">
								7 </span>
								</a>
							</li>
							<li class="divider">
							</li>
							<li>
								<a href="logout.jsp?logoff=yes">
								<i class="icon-key"></i> Log Out </a>
							</li>
						</ul>
					</li>
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
	<!-- BEGIN SIDEBAR -->
	<div class="page-sidebar-wrapper">
		<!-- DOC: Set data-auto-scroll="false" to disable the sidebar from auto scrolling/focusing -->
		<!-- DOC: Change data-auto-speed="200" to adjust the sub menu slide up/down speed -->
		<div class="page-sidebar navbar-collapse collapse">
			<%= web.getMenu() %>

			<!-- END SIDEBAR MENU -->
		</div>
	</div>
	<!-- END SIDEBAR -->
	<!-- BEGIN CONTENT -->
	<div class="page-content-wrapper">
		<div class="page-content">

			<!-- BEGIN PAGE CONTENT-->
			<form id="baraza" name="baraza" method="post" action="index.jsp" data-confirm-send="false" data-ajax="false">
				<%= web.getHiddenValues() %>
			<div class="row">
				<div class="col-md-12" >
					<div class="tabbable tabbable-tabdrop"><%= web.getTabs() %></div>
					<% if(opResult != null) out.println("<div style='color:#FF0000'>" + opResult + "</div>"); %>
					<%= web.getSaveMsg() %>

					<div class="portlet box purple">
                        
                        
						<div class="portlet-title">
							<div class="caption">
								<i class="fa fa-cogs"></i><%= web.getViewName() %>
							</div>
							<div class="tools">
								<a href="javascript:;" class="collapse">
								</a>
								<a href="javascript:;" class="reload">
								</a>
								<a href="javascript:;" class="remove">
								</a>
							</div>
							<%= web.getButtons() %>
						</div>
						<div class="portlet-body">
							<div class="table-scrollable">
								<%= web.getBody(request, reportPath) %>
							</div>
						</div>

						<%= web.getFilters() %>

						<% String actionOp = web.getOperations();
						if(actionOp != null) {	%>
							
                               
                            <div class="row" style="">
                                <div class="col-md-2" >
                                    <%= actionOp %>
                                </div>
                                    
                                <div class="col-md-1" >
                                    <button type="button" id="btnAction" name="process" value="Action" class="btn btn-sm green">Action</button>
                                </div>
                            </div>
						  	
						<%	} %>

						<% if(fieldTitles != null) { %>
							<table class="table" style="margin-bottom:0px;"><tr>
								<td ><%= fieldTitles %></td>
								<td >
									<select class='fnctcombobox form-control' name='filtertype'>
										<option value='ilike'>Contains (case insensitive)</option>
										<option value='like'>Contains (case sensitive)</option>
										<option value='='>Equal to</option>
										<option value='>'>Greater than</option>
										<option value='<'>Less than</option>
										<option value='<='>Less or Equal</option>
										<option value='>='>Greater or Equal</option>
									</select>
								</td>
								<td ><input class="form-control" name="reportfilter" type="text" id="search" /></td>
								<td ><input class="form-control" name='and' type='checkbox'/> And</td>
								<td ><input class="form-control" name='or' type='checkbox' /> Or</td>
								<td ><button class="form-control" class="i_magnifying_glass icon small" name="search" value="Search">Search</button></td>
								<td ></td>
								<td ><button class="btn btn-sm green" name="sortasc" id="ascending" value=" "><i class="fa fa-angle-up"></i>&nbsp;&nbsp;ASC</button></td>
								<td ><button class="btn btn-sm blue" name="sortdesc" id="descending" value=" "><i class="fa fa-angle-down"></i>&nbsp;&nbsp;DESC</button></td>
							</tr></table>
						<% } %>

						<%= web.showFooter() %>
					</div>
				</div>
			</div>
			</form>
			
			
			
	<script type="text/javascript">
	
	
 var chatWindowArray = [];
    
    var config = {
        contextPath: '${pageContext.request.contextPath}'
    };
	
	function getChatWindowByUserPair(loginUserName, peerUserName) {
		
		var chatWindow;
		
		for(var i = 0; i < chatWindowArray.length; i++) {
			var windowInfo = chatWindowArray[i];
			if (windowInfo.loginUserName == loginUserName && windowInfo.peerUserName == peerUserName) {
				chatWindow =  windowInfo.windowObj;
			}
		}
		
		return chatWindow;
	}
	
	function createWindow(loginUserName, peerUserName) {
	
	
	if(loginUserName == 'Dewcis' || peerUserName == 'Dewcis'){
	
		
		var chatWindow = getChatWindowByUserPair(loginUserName, peerUserName);
		
		if (chatWindow == null) { //Not chat window created before for this user pair.
			chatWindow = new ChatWindow(); //Create new chat window.
			chatWindow.initWindow({
				loginUserName:loginUserName, 
				peerUserName:peerUserName,
				windowArray:chatWindowArray});
			
			//collect all chat windows opended so far.
			var chatWindowInfo = { peerUserName:peerUserName, 
					               loginUserName:loginUserName,
					               windowObj:chatWindow 
					             };
					             
			
			chatWindowArray.push(chatWindowInfo);
			}
    	}
		
		chatWindow.show();
		
		return chatWindow;
	}

	function join(userName){
		chat.cometChat.join(userName);
	}
</script>
	

			
		</div>
	</div>
	<!-- END CONTENT -->
</div>
<!-- END CONTAINER -->
<!-- BEGIN FOOTER -->
<div class="page-footer">
	<div class="page-footer-inner">
		2015 &copy; Open Baraza. <a href="http://dewcis.com">Dew Cis Solutions Ltd.</a> All Rights Reserved
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

<script src="./assets/global/plugins/jquery-inputmask/jquery.inputmask.bundle.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/select2/select2.min.js" type="text/javascript"></script>

<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/morris/morris.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/morris/raphael-min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.sparkline.min.js" type="text/javascript"></script>
<!-- END PAGE LEVEL PLUGINS -->
<!-- BEGIN PAGE LEVEL SCRIPTS -->
<script src="./assets/global/scripts/metronic.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/layout.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/demo.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/index3.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/tasks.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/components-pickers.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.multi-select.js" type="text/javascript" ></script>

<!-- END PAGE LEVEL SCRIPTS -->

<script type="text/javascript" src="./assets/jqgrid/js/i18n/grid.locale-en.js"></script>
<script type="text/javascript" src="./assets/jqgrid/js/jquery.jqGrid.min.js"></script>

	<script>
		jQuery(document).ready(function() {    
            
		   Metronic.init(); // init metronic core componets
		   Layout.init(); // init layout
		   //Demo.init(); // init demo features 
		   //Index.init(); // init index page
		   //Tasks.initDashboardWidget(); // init tash dashboard widget  
		   //ComponentsPickers.init();
            
            $('.date-picker').datepicker();
            
            //alert($(".mask_currency").length);
            
            $('.multi-select').multiSelect();
            
            /*$(".mask_currency").each(function(i, obj){
                var mask = $(this).attr('data-mask');
                $(this).inputmask(mask, {
                    numericInput: true
                });
            });*/

            $('.select2me').select2({
                placeholder: "Select an option",
                allowClear: true
            });
		});
	</script>

	<script>
	<% if(web.isGrid()) { %>
		var jqcf = <%= web.getJSONHeader() %>;

        jqcf.rowNum = 20;
        jqcf.height = 300;
        
        <% if(actionOp != null) {	%>
		  jqcf.multiselect = true;
	    <% } %>

		jQuery("#jqlist").jqGrid(jqcf);
		jQuery("#jqlist").jqGrid("navGrid", "#jqpager", {edit:false,add:false,del:false});  
        
		$("#jqlist").dblclick(function(){
			var rowId =$("#jqlist").jqGrid('getGridParam','selrow');  
			var rowData = jQuery("#jqlist").getRowData(rowId);
			var colData = rowData['CL'];

			location.replace(colData);
		});                                 
        
        $('#btnAction').click(function(){
            var operation = $("#operation").val();

            var $grid = $("#jqlist"), selIds = $grid.jqGrid("getGridParam", "selarrrow"), i, n, cellValues = [];
            for (i = 0, n = selIds.length; i < n; i++) {
                var coldata = $grid.jqGrid("getCell", selIds[i], "CL");
                var begin = coldata.lastIndexOf("=");
                var end = coldata.length;
                var id = coldata.substring(begin + 1, end);
                cellValues.push(id);
            }
            if(cellValues.join(",") == ""){
                alert('No row Selected');
            } else {
                //alert(cellValues.join(",")); 
                //cellValues.join(",") returns 1,2,3,4
                $.post("ajax?fnct=operation&id=" + operation, {ids: cellValues.join(",")}, function(data){

                }, "JSON");
            }            
        });
	<% } %>
	</script>
	
	
	
	
	
<!-- END JAVASCRIPTS -->
</body>
<!-- END BODY -->
</html>

<% 	web.close(); %>
