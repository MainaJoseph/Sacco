/**
 * @author Semika Siriwardana(semika.siriwardana@gmail.com)
 */
function ChatWindow(config) {
	
	var _self = this;
	var _peerUserName;
	var _loginUserName;
	var _config;
	this._windowWidth  = 300;
	this._windowHeight = 270;
	this.lastUser      = null;
	this.windowArray   = [];
	var enter_text;
	
	var windowDIV10=document.createElement("div");
	windowDIV10.setAttribute("class","row");
	windowDIV10.setAttribute("id","chat_body");
	
	
	
	
	this.getWindowLeftPosition = function() {
		return this.windowArray.length*this._windowWidth;
		
	},
	
	this.getPeerUserName = function() {
		return this._peerUserName;
	};
	
	this.getLoginUserName = function() {
		return this._loginUserName;
	};
	
	
	this.getTextInputID = function() {
		return this.getLoginUserName() + "_" + this.getPeerUserName() + "_chatInput";
	};
	
	this.getWindowID = function() {
		return this.getLoginUserName() + "_" + this.getPeerUserName() + "_window";
	};
	
	
	
	this.hide = function(_self) {
		$("#" + _self.getWindowID()).css("display", "none");
	};
	
	this.show = function() {
		$("#" + this.getWindowID()).css("display", "block");
	};
	
	
	
	/**
	 * Returns whether the chat window is currently visible or not
	 */
	this.isVisible = function() {
		return $("#" + this.getWindowID()).css("display") == "none"?false:true;
	};
	
	this.addOnClickListener = function(el, fnHandler, context) {
		$(el).bind("click", context, function(evt) {
			if(context != undefined) {
				fnHandler(context);
			} else {
				fnHandler();
			}
			return false;
		});
	};
	
	this.appendMessage = function(fromUser, text, loginUser) {
		
		var userNameCssClass    = "";
		var textMessageCssClass = "";
		
		if (fromUser == loginUser) {
			fromUser= 'me';
			userNameCssClass    = "fromUserName";
			textMessageCssClass = "fromMessage";
		} else {
			userNameCssClass    = "toUserName";
			textMessageCssClass = "toMessage";
		}
		
		if (this.lastUser == fromUser) {
			fromUser = "...";
		} else {
			this.lastUser = fromUser;
			fromUser += ':';
		}
		var chatContainer = $("#" + this.getMessageContainerID());
		var sb = [];
		sb[sb.length] = '<span class="' + userNameCssClass + '">' + fromUser + '</span>';
		sb[sb.length] = '<span class="' + textMessageCssClass + '">' + text + '</span><br/>';
		chatContainer.append(sb.join(""));  
		//chatContainer[0].scrollTop = chatContainer[0].scrollHeight - chatContainer.outerHeight();
	};
	
	this.focusTextInput = function() {
		$("#" + this.getTextInputID()).focus();
	},
	
	
	
	
	
	this.getWindowHTML = function() {
		
		var windowDIV = document.createElement("div");
		windowDIV.setAttribute("id", this.getWindowID());
		
		var windowDIV1= document.createElement("div");
		
		windowDIV1.setAttribute("class","portlet portlet-default");
		windowDIV1.style.right    = this.getWindowLeftPosition() + "px";
		var windowDIV2= document.createElement("div");
		windowDIV2.setAttribute("class","portlet-heading");
		var windowDIV3=document.createElement("div");
		windowDIV3.setAttribute("class","portlet-title");
		var windowDIV11= document.createElement("h4");
		
		
		var windowDIV12=document.createElement("i");
		windowDIV12.innerHTML=this.getPeerUserName();
		windowDIV12.setAttribute("class","fa fa-circle text-green");
		windowDIV11.appendChild(windowDIV12);
		windowDIV3.appendChild(windowDIV11);
		
		var windowDIV4=document.createElement("div");
		windowDIV4.setAttribute("class","portlet-widgets");
		
		var windowDIV15= document.createElement("a");
		windowDIV15.setAttribute("href","#chat");
		windowDIV15.setAttribute("data-toggle","collapse");
		windowDIV15.setAttribute("class","collapsed");
		windowDIV15.setAttribute("aria-expanded","false");
		
		var windowDIV16= document.createElement("i");
		windowDIV16.setAttribute("class","fa fa-chevron-down");
		windowDIV15.appendChild(windowDIV16);
		
		
		var windowDIV13=document.createElement("a");
		windowDIV13.setAttribute("class","btn-group");
		
		var windowDIV14= document.createElement("div");
		windowDIV14.setAttribute("class","clearfix");
		windowDIV4.appendChild(windowDIV15);
		windowDIV2.appendChild(windowDIV3);
		windowDIV2.appendChild(windowDIV4);
		windowDIV2.appendChild(windowDIV14);
		
		
		var windowDIV5=document.createElement("div");
		windowDIV5.setAttribute("class","panel-collapse collapse in");
		
		windowDIV5.setAttribute("id","chat");
		
		var windowDIV6=document.createElement("div");  
		windowDIV6.setAttribute("class","portlet-body chat-widget");
		windowDIV6.style.overflowY="auto";
		windowDIV6.style.width      = "300px";
		windowDIV6.style.height     = "270px";
		
		windowDIV6.appendChild(windowDIV10);
		
		var windowDIV7=document.createElement("div");  
		windowDIV7.setAttribute("class","portlet-footer");
		var windowDIV8=document.createElement("div"); 
		windowDIV8.setAttribute("class","form-group");
		var windowDIV9= document.createElement("textarea");
		
		enter_text= this.getWindowID()+ "_chat_id";
		
		windowDIV9.setAttribute("id",enter_text);
		windowDIV9.setAttribute("class","form-control");
		//windowDIV9.style.placeholder="Enter message...";
		windowDIV8.appendChild(windowDIV9);
		windowDIV7.appendChild(windowDIV8);
		windowDIV5.appendChild(windowDIV6);
		windowDIV5.appendChild(windowDIV7);
		windowDIV1.appendChild(windowDIV2);
		windowDIV1.appendChild(windowDIV5);
		windowDIV.appendChild(windowDIV1);
		
		return windowDIV;
		
	};
	
	this.initWindow = function(config) {
		this._config = config;
		this._peerUserName    = config.peerUserName;
		this._loginUserName   = config.loginUserName;
		this.windowArray      = config.windowArray;
		
		var body = document.getElementsByTagName('body')[0];
		
		
		body.appendChild(this.getWindowHTML()); 
		
		
		this.getMessageContainerID = function() {
			
			var chat1= this.getLoginUserName() + "_" + this.getPeerUserName();
			//var chatclass = document.getElementById("chat_body");
			//chatclass.setAttribute("id",chat1);
			
			windowDIV10.id=chat1;
			
			return chat1;
			
		};
		
		
		
		$("#" + enter_text).keyup(function(e) {
			if (e.keyCode == 13) {
				
				// alert($("#enter_text").val());
				
				// document.getElementById("message_input").innerHTML=$('textarea').val();
				//var row_input= document.getElementById("row_input");
				//windowapp.appendChild(row_input);
				
				
				
				chat.cometChat.send($("#" + enter_text).val(), _self.getPeerUserName());
				$("#" + enter_text).val('');
				$("#" + enter_text).focus();
				
			}
		});
		
		
		
		//focus text input just after opening window
		this.focusTextInput();
	};
	
	
}