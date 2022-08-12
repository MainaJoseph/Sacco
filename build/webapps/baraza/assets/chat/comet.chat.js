/**
 * @author Semika siriwardana(semika.siriwardana@gmail.com)
 */
(function($){
	
	$.cometChat = {
		
		_connected:false,
		loginUserName:undefined,
		_disconnecting:undefined,
		_chatSubscription:undefined,
		_membersSubscription:undefined,
		memberListContainerID:undefined, //'id' of a 'div' or 'span' tag which keeps list of online users.
		
		/**
		 * This method can be invoked to disconnect from the chat server.
		 * When user logging off or user close the browser window, user should
		 * be disconnected from cometd server.
		 */
		leave: function() {
            $.cometd.batch(function() {
                $.cometChat._unsubscribe();
            });
            $.cometd.disconnect();

            $.cometChat.loginUserName  = null;
            $.cometChat._disconnecting = true;
        },
		
        /**
         * Handshake with the server. When user logging into your system, you can call this method
         * to connect that user to cometd server. With that user will subscribe with tow channel.
         * '/chat/demo' and '/members/demo' and start to listen to those channels. 
         */
		join: function(username) {
			
			$.cometChat._disconnecting = false;
			$.cometChat.loginUserName  = username;

            var cometdURL = location.protocol + "//" + location.host + config.contextPath + "/cometd";

            $.cometd.configure({
                url: cometdURL,
                logLevel: 'debug'
            });
            $.cometd.websocketEnabled = false;
            $.cometd.handshake();
		},
		
		/**
		 * Send the text message to peer as a private message. Private messages
		 * are visible only for relevant peer users.
		 */
		send:function(textMessage, peerUserName) {
            
			if (!textMessage || !textMessage.length) return;

            $.cometd.publish('/service/privatechat', {
                room: '/chat/demo',
                user: $.cometChat.loginUserName,
                chat: textMessage,
                peer: peerUserName
            });
        },
        
		 /**
         * Updates the members list.
         * This function is called when a message arrives on channel /chat/members
         */
        members:function(message) {
            var sb = [];
            $.each(message.data, function() {
            	if ($.cometChat.loginUserName == this) { //login user
            		sb[sb.length] = "<span style=\";color: #FF0000;\">" + this + "</span><br>";
            	} else { //peer users
            		sb[sb.length] = "<span onclick=\"javascript:createWindow('" + $.cometChat.loginUserName + "', '" + this + "');\"  style=\"cursor: pointer;color: #0000FF;\">" + this + "</span><br>";
            	}
            });
			
            $('#'+ $.cometChat.memberListContainerID).html(sb.join("")); 
			
			var member_size = sb.length;
			
			$( "#members" ).before("<b>" + member_size + "</b>" + " Online Members");
			
			
        },

        
        /**
         * This function will be invoked every time when '/chat/demo' channel receives a message.
         */
		receive :function(message) {
			
            var fromUser = message.data.user;
            var text     = message.data.chat;
            var toUser   = message.data.peer;
            
            //Handle receiving messages
            if ($.cometChat.loginUserName == toUser) {
            	//'toUser' is the loginUser and 'fromUser' is the peer user.
            	var chatReceivingWindow = createWindow(toUser, fromUser);
            	chatReceivingWindow.appendMessage(fromUser, text, $.cometChat.loginUserName);
            }
            
            //Handle sending messages
            if ($.cometChat.loginUserName == fromUser) {
            	//'fromUser' is the loginUser and 'toUser' is the peer user.
            	var	chatSendingWindow = createWindow(fromUser, toUser);
            	chatSendingWindow.appendMessage(fromUser, text, $.cometChat.loginUserName);
            }
        },
        
        _unsubscribe: function() {
            if ($.cometChat._chatSubscription) {
                $.cometd.unsubscribe($.cometChat._chatSubscription);
            }
            $.cometChat._chatSubscription = null;
            
            if ($.cometChat._membersSubscription) {
                $.cometd.unsubscribe($.cometChat._membersSubscription);
            }
            $.cometChat._membersSubscription = null;
        },
        
        _connectionEstablished: function() {
            // connection establish (maybe not for first time), so just
            // tell local user and update membership
            $.cometd.publish('/service/members', {
                user: $.cometChat.loginUserName,
                room: '/chat/demo'
            });
        },
        
        _connectionBroken: function() {
            $('#' + $.cometChat.memberListContainerID).empty();
        },
        
        _connectionClosed: function() {
           /* $.cometChat.receive({
                data: {
                    user: 'system',
                    chat: 'Connection to Server Closed'
                }
            });*/
        },
        
        _metaConnect: function(message) {
            if ($.cometChat._disconnecting) {
            	$.cometChat._connected = false;
            	$.cometChat._connectionClosed();
            } else {
                var wasConnected = $.cometChat._connected;
                $.cometChat._connected = message.successful === true;
                if (!wasConnected && $.cometChat._connected) {
                	$.cometChat._connectionEstablished();
                } else if (wasConnected && !$.cometChat._connected) {
                	$.cometChat._connectionBroken();
                }
            }
        },
        
        _subscribe: function() {
			$.cometChat._chatSubscription    = $.cometd.subscribe('/chat/demo',    $.cometChat.receive); //channel handling chat messages
			$.cometChat._membersSubscription = $.cometd.subscribe('/members/demo', $.cometChat.members); //channel handling members.
        },
        
        _connectionInitialized: function() {
            // first time connection for this client, so subscribe tell everybody.
            $.cometd.batch(function() {
            	$.cometChat._subscribe();
            });
        },
        
		_metaHandshake: function (message) {
            if (message.successful) {
            	$.cometChat._connectionInitialized();
            }
        },
        
		_initListeners: function() {
			$.cometd.addListener('/meta/handshake', $.cometChat._metaHandshake);
	        $.cometd.addListener('/meta/connect',   $.cometChat._metaConnect);
	        
	        $(window).unload(function() {
	        	$.cometd.reload();
                $.cometd.disconnect();
	        });
		},		
			
		onLoad: function(config) {
			$.cometChat.memberListContainerID = config.memberListContainerID;
			$.cometChat._initListeners();
		},
 
	};
	
	
})(jQuery);


