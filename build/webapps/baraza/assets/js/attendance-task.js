
var btnrmvClass = 'btn-primary';
var btnaddClassError = 'btn-danger';
var btnaddClass = 'btn-success';
var btnaddClassWarning = 'btn-warning';
var labelrmvClass = 'label-primary';
var labeladdClass = 'label-success';
var labeladdClassError = 'label-danger';
var btnLunch = $(".lunch-break-btn");
var btnLunchOut = $('.lunch-break-out-btn');
var btnBreak = $(".break-btn");
var btnBreakOut = $('.break-out-btn');
var btnClockIn = $(".clock-in-btn");
var btnClockOut = $(".clock-out-btn");
const IN = 'IN';
var latitude = 0;
var longitude = 0;
var netError = document.getElementById("netError");
/**
 * Clock In Button JS
 **/
btnClockIn
    .click(function () {
        var btnClock = $(this);
        var unHideBtnClock = $('.clock-out-btn');
        var btnClockStatus = $('.clock-in-status-btn');
        var msg = 'Clocked In : 8:00am ';
        btnClock.button('loading');
        reqLocation(btnClock, unHideBtnClock, btnClockStatus, msg, '1', 'IN');
    });

/**
 * Clock Out Button JS
 **/
btnClockOut
    .click(function () {
        var btnClock = $(this);
        var unHideBtnClock = $('.clock-out-btn');
        var btnClockStatus = $('.clock-in-status-btn');
        var msg = 'Clocked In Time : 8:00am ';
        btnClock.button('loading');
        reqLocation(btnClock, unHideBtnClock, btnClockStatus, msg,  '1', 'OUT');
    });


/**
 *
 * Lunch Break Button JS
 **/
btnLunch
    .click(function () {
        var btnClock = $(this);
        var btnClockStatus = $('.lunch-break-status-btn');
        var msg = 'Lunch End : 2:00pm ';
        btnClock.button('loading');
        reqLocation(btnClock, btnLunchOut, btnClockStatus, msg, '4', 'LUNCHIN');
    });

/**
 *
 * Lunch Out Button JS
 **/
btnLunchOut
    .click(function () {
        var btnClock = $(this);
        var btnClockStatus = $('.lunch-break-status-btn');
        var msg = 'Lunch End : 2:00pm ';
        btnClock.button('loading');
        reqLocation(btnClock, btnLunch, btnClockStatus, msg, '4', 'LUNCHOUT');
    });

/**
 * Evening Break Button JS
 **/
btnBreak
    .click(function () {
        var btnClock = $(this);
        var btnClockStatus = $('.break-status-btn');
        var msg = 'Break End : 4:30pm ';
        btnClock.button('loading');
        reqLocation(btnClock, btnBreakOut, btnClockStatus, msg, '7', 'BREAKIN');
    });

/**
 * Evening Break Out Button JS
 **/
btnBreakOut
    .click(function () {
        var btnClock = $(this);
        var btnClockStatus = $('.break-status-btn');
        var msg = 'Break End : 4:30pm ';
        btnClock.button('loading');
        reqLocation(btnClock, btnBreak, btnClockStatus, msg, '7', 'BREAKOUT');
    });

/**
 * Function for ajax and Color scheme
 * @param btnEnrtryCss
 * @param btnStatusCss
 * @param msg
 */
function postAjax(btnEnrtryCss, unHideBtn, btnStatusCss, msg, logType, logInOut, latitude, longitude){
    var btnClock  = $(btnEnrtryCss);
    var btnClockStatus = $(btnStatusCss);
    var oldBtnClass = '';
    var outBtnNewClassName = '';
    var jsonData =                 {
        log_type: logType,
        log_in_out: logInOut,
        lat: latitude,
        long: longitude
    };

    $.ajax({
        url: 'ajax', // url where to submit the request
        type : "POST", // type of action POST || GET
        dataType : 'json', // data type
        data : {"fnct":"attendance","json":JSON.stringify(jsonData)}, // post data || get data
        beforeSend: function() {//calls the loader id tag
            $(".submit i").removeAttr('class').addClass("fa fa-refresh fa-spin fa-3x fa-fw  text-center").css({"color":"#fff",});
        },
        success : function(result) {
            var btnMsg = 'DONE';
            for(var data in result){
                var log_type = result[data].log_type;
                var log_in_out = result[data].log_in_out;
                msg = '';
                if(log_type == 1){
                    //btnMsg = "CLOCK OUT";
                    //outBtnNewClassName = 'clock-out-btn' ;
                    //oldBtnClass  = 'clock-in-btn';
                    //msg = 'Clocked In Time :'+result[data].log_time;

                    if(logInOut == 'IN'){
                        btnMsg = "CLOCK OUT";
                        msg = 'Clocked In :'+result[data].log_time;
                        outBtnNewClassName = 'clock-out-btn' ;
                        oldBtnClass  = 'clock-in-btn';


                        //btnClock.removeAttr("disabled");
                        btnLunch.removeAttr("disabled");//if clocked in activate lunch button
                        btnBreak.removeAttr("disabled");//if clocked in activate break button

                        btnClockIn.hide();//hide clocin in button
                        btnClockOut.show();//show clock out button
                        btnLunchOut.hide();//hide the lunchout button
                        btnBreakOut.hide();//hide the breakout button

                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);
                    }
                    if(logInOut == 'OUT'){
                        btnMsg = "CLOCKING DONE";
                        msg = 'Clocked Out : '+result[data].log_time;
                        outBtnNewClassName = 'clock-out-btn' ;
                        oldBtnClass  = 'clock-in-btn';

                        //hide all in buttons when fully done for the day
                        btnClockIn.hide();
                        btnLunch.hide();
                        btnBreak.hide();
                        btnLunchOut.show();
                        btnBreakOut.show();
                        btnLunchOut.html('LUNCH DONE');
                        btnBreakOut.html('BREAK DONE');


                        //disable all clockout buttons
                        btnClockOut.attr('disabled','disabled');
                        btnClockIn.attr('disabled','disabled');
                        btnLunch.attr('disabled','disabled');
                        btnLunchOut.attr('disabled','disabled');
                        btnBreakOut.attr('disabled','disabled');
                        btnBreak.attr('disabled','disabled');

                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);

                    }
                }
                if(log_type == 4){
                    if(logInOut == 'LUNCHIN'){
                        btnMsg = "LUNCH OUT";
                        msg = 'Lunch Start :'+result[data].log_time;
                        outBtnNewClassName = 'lunch-break-out-btn' ;
                        oldBtnClass  = 'lunch-break-btn';

                        //disable break in/out and disable clock out
                        btnClockOut.attr('disabled','disabled');
                        btnBreak.attr('disabled','disabled');


                        //hide the clock in and lunch in show lunch out
                        btnClockIn.hide();
                        btnLunch.hide();
                        btnLunchOut.show();
                        //btnBreakOut.hide();//hide break button

                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);
                    }
                    if(logInOut == 'LUNCHOUT'){
                        btnMsg = "LUNCH DONE";
                        msg = 'Lunch End :'+result[data].log_time;
                        outBtnNewClassName = 'lunch-break-out-btn';
                        oldBtnClass  = 'lunch-break-btn';

                        //enable break in/out and enable clock out
                        btnClockOut.removeAttr('disabled');
                        btnBreak.removeAttr('disabled');



                        //hide the clock in and lunch in show lunch out
                        btnClockIn.hide();
                        btnLunch.hide();
                        btnLunchOut.show();
                        btnBreakOut.hide();//hide break button

                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);
                        btnLunch.html('LUNCH DONE');


                    }
                }

                if(log_type == 7){
                    if(logInOut == 'BREAKIN'){
                        btnMsg = "BREAK OUT";
                        outBtnNewClassName = 'break-out-btn';
                        oldBtnClass  = 'break-btn';
                        msg = 'Break Start :'+result[data].log_time;

                        //Disable Clock out and lunch out
                        btnClockOut.attr('disabled','disabled');
                        btnLunchOut.attr('disabled','disabled');
                        btnLunch.attr('disabled','disabled');

                        //hide break in,hide lunchin clock in show breakout
                        btnBreak.hide();
                        btnBreakOut.show();
                        //btnLunch.hide();
                        //btnLunchOut.hide();
                        //btnClockIn.hide();
                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);
                        btnBreak.removeAttr('disabled');
                        btnBreakOut.removeAttr('disabled');
                        btnBreakOut.html('BREAK OUT');
                    }
                    if(logInOut == 'BREAKOUT'){
                        btnMsg = "BREAK";
                        outBtnNewClassName = 'break-out-btn';
                        oldBtnClass  = 'break-btn';
                        msg = 'Break End :'+result[data].log_time;

                        //Enable Clock out and disable break
                        btnClockOut.removeAttr('disabled');
                        btnLunchOut.removeAttr('disabled');
                        btnLunch.removeAttr('disabled');
                        //btnBreakOut.attr('disabled','disabled');

                        //hide break in,hide lunchin clock in show breakout
                        btnBreak.hide();
                        btnBreakOut.show();
                        //btnLunch.hide();
                        //btnLunchOut.hide();
                        btnClockIn.hide();

                        buttonVisible(btnClock,unHideBtn,  btnClockStatus, labelrmvClass, btnStatusCss, labeladdClass, msg);
                        btnBreak.html('BREAK');

                    }
                }

            }
            changeBtnMsg(btnClock, btnMsg);

            //colorChange(btnClock, btnClockStatus, oldBtnClass, btnrmvClass, labelrmvClass,
            //    btnStatusCss, btnaddClass, labeladdClass, btnMsg, msg, outBtnNewClassName);

        },
        error: function(xhr, resp, text) {
            var btnMsg = 'Contact System Admin';
            var labelMsg = 'An error Occured';
            colorChange(btnClock, btnClockStatus, oldBtnClass, btnrmvClass, labelrmvClass,
                btnStatusCss, btnaddClassError, labeladdClassError, btnMsg, labelMsg, '');
        }

    });
}
/**
 *
 * @param hidebtnClock
 * @param unhidebtnClock
 * @param btnClockStatus
 * @param labelrmvClass
 * @param btnStatusCss
 * @param labeladdClass
 * @param labelMsg
 */
function buttonVisible(hidebtnClock, unhidebtnClock, btnClockStatus, labelrmvClass, btnStatusCss,
                       labeladdClass, labelMsg){
    hidebtnClock.hide();
    unhidebtnClock.show();

    btnClockStatus.removeClass('label '+ labelrmvClass +' '+ btnStatusCss);
    btnClockStatus.addClass('label '+ labeladdClass +' '+ btnStatusCss);
    btnClockStatus.html(labelMsg);
}
/**
 *
 * @param btnClass
 * @param btnMsg
 */
function changeBtnMsg(btnClass, btnMsg){
    btnClass.html(btnMsg);
}


$('.tasks-manage').select2({
    placeholder: "Select",
    allowClear: true
});

$('#start-task')
    .click(function () {
        var btnId = $('.start-task');
        var btnRId = $('#start-task');
        var json = $('#task-manage').serializeArray();
        console.log(" select " + json);
        var jsonData = {task:"start"};
        $.each(json, function(i, field){
            jsonData [field.name] = field.value;
        });
        $.ajax({

            url: 'ajax', // url where to submit the request
            type : "POST", // type of action POST || GET
            dataType : 'json', // data type
            data : {"fnct":"task","json":JSON.stringify(jsonData)}, // post data || get data
            beforeSend: function() {//calls the loader id tag
                //                $("#loader").show();
                $(".start-task i").removeAttr('class').addClass("fa fa-refresh fa-spin fa-3x fa-fw  text-center").css({"color":"#fff",});
            },
            success : function(result) {
                console.log("Task Name here " + result[0].task_name);
                //If successfull hide the form display the display
                $('.task-manage-form').hide();
                $('#display-task').show();
                //dispalys the value
                $('#tsk_name').html(result[0].task_name);
                $('#end_task').val(result[0].timesheet_id);
                $(".start-task i").removeAttr('class').addClass("").css({"color":"#fff",});
            },
            error: function(xhr, resp, text) {
                var btnMsg = "<i class='fa fa-warning text-center'></i> Save Failed";
                btnaddClass = 'btn-danger';
                $('#end-task').show();
                colorChange(btnId, null, btnId, btnrmvClass, '',
                    '', btnaddClass, '', btnMsg, '');

            }

        });

    });

$('#end_task')
    .click(function () {
        btnrmvClass = 'btn-warning';
        var btnId = $('.end-task');
        var timesheetId = $('#end_task').val();
        var json = $('#task-manage').serializeArray();
        console.log(" select " + json);
        var jsonData =  {
            task: "stop",
            timesheet_id:timesheetId
        };
        $.ajax({
            url: 'ajax', // url where to submit the request
            type : "POST", // type of action POST || GET
            dataType : 'json', // data type
            data : {"fnct":"task","json":JSON.stringify(jsonData)}, // post data || get data
            beforeSend: function() {//calls the loader id tag
                //$('#start-task').hide();
                $(".end-task i").removeAttr('class').addClass("fa fa-refresh fa-spin fa-3x fa-fw  text-center").css({"color":"#fff",});
                $('.task-manage-form').show();
                $('#display-task').hide();
            },
            success : function(result) {
                var btnMsg = "<i class='fa fa-check  text-center'></i> Saved Successfully";
                colorChange(btnId, '', btnId, btnrmvClass, '',
                    '', btnaddClass, '', btnMsg, '');
                //If successfull hide the form display the display
                $('.task-manage-form').show();
                $('#display-task').hide();

                $(".start-task i").removeAttr('class').addClass("").css({"color":"#fff",});
                $(".end-task i").removeAttr('class').addClass("").css({"color":"#fff",});
            },
            error: function(xhr, resp, text) {
                var btnMsg = "<i class='fa fa-warning  text-center'></i> Save Failed";
                btnaddClass = 'btn-danger';
                colorChange(btnId, '', btnId, btnrmvClass, '',
                    '', btnaddClass, '', btnMsg, '');
            }

        });

    });
/**
 * Javascript handle Color Transformations
 * @param btnClock
 * @param btnClockStatus
 * @param btnEnrtryCss
 * @param btnrmvClass
 * @param labelrmvClass
 * @param btnStatusCss
 * @param btnaddClass
 * @param labeladdClass
 */
function colorChange(btnClock , btnClockStatus, btnEnrtryCss, btnrmvClass, labelrmvClass,
                     btnStatusCss, btnaddClass, labeladdClass, btnMsg, labelMsg, outBtnoldBtnClassName){
//        btnClock.button('reset');
    btnClock.removeClass(btnEnrtryCss +' btn-block btn-sm '+ btnrmvClass);
    btnClock.addClass(outBtnoldBtnClassName +' btn-block btn-sm '+ btnaddClass);
    btnClock.html(btnMsg);

    btnClockStatus.removeClass('label '+ labelrmvClass +' '+ btnStatusCss);
    btnClockStatus.addClass('label '+ labeladdClass +' '+ btnStatusCss);
    btnClockStatus.html(labelMsg);
}

/**
 * Function to request location and ajax call
 * @param btnClock
 * @param unHideBtnClock
 * @param btnClockStatus
 * @param msg
 * @param num
 * @param onOut
 */
function reqLocation(btnClock, unHideBtnClock, btnClockStatus, msg, num , onOut){
    getLocation();
    function getLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(showPosition);
        } else {
            netError.innerHTML = "Geolocation is not supported by this browser.";
        }
    }

    function showPosition(position) {
        latitude = position.coords.latitude;
        longitude = position.coords.longitude;
        //Send the lat & long to Ajax
        postAjax(btnClock, unHideBtnClock, btnClockStatus, msg, num, onOut, latitude, longitude);
    }

}


