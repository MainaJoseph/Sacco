        <div class="col-md-6 col-sm-12">
            <!-- BEGIN PORTLET-->
            <div class="portlet light tasks-widget">
                <div class="portlet-title" style="display: none;">
                    <div class="caption caption-md">
                        <i class="icon-bar-chart theme-font-color hide"></i>
                        <span class="caption-subject theme-font-color bold uppercase">Tasks</span>
                        <span class="caption-helper"> Select a task to activate.</span>
                    </div>
                </div>
                <div class="portlet-body">
				<!-- TASK FORM-->
                    <form class="task-manage-form form-horizontal" id="task-manage" method="post">
                        <div class="form-group">
                            <label class="control-label col-sm-2 font-600" for="task_name">Task</label>
                            <div class="col-sm-10 col-xs-12">
                                <select class="form-control tasks-manage" id="task_name" name="task_name" data-placeholder="Select Task">
                                    <option value=""></option>
                                    <%=web.getDashboardItem("taskList")%>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="control-label col-sm-2 font-600" for="task_narrative">Narrative</label>
                            <div class="col-sm-10 col-xs-12">
                                <textarea id="task_narrative" class="width-100" name="task_narrative"></textarea>
                            </div>
                        </div>
                        <div class="row">
                        <div class="col-md-6 col-xs-6">
                            <button  type="button" id="start-task" class="start-task btn-block btn-sm btn-primary">
                                <i class=""></i> Start Task
                            </button>
                            <%--<button  type="button" id="end-task" class="end-task btn-block btn-sm btn-warning" style="display:none">--%>
                                <%--<i class=""></i> End Task--%>
                            <%--</button>--%>
                        </div>
                        <div class="col-md-6 col-xs-6">
                        </div>
                        </div>
                    </form>
                <!-- TASK FORM-->
				<!-- DISPLAY TASK-->
                    <div class="table-scrollable" id="display-task">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Task Name</th>
                                    <th>Status</th>
                                    <th>Operation</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td id="tsk_name"> </td>
                                    <td><span class="label label-sm label-success">In Progress</span></td>
                                    <td>
                                        <button  type="button" id="end_task" class="btn btn-xs red" value="">
                                            <i class="fa  fa-hand-o-up"></i> End Task
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
				<!-- DISPLAY TASK-->
				</div>
            </div>
        </div>
