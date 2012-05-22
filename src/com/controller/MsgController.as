package com.controller
{
	import com.Elements.MySnake;
	import com.Elements.RemoteSnake;
	import com.events.CustomEvent;
	import com.model.PlayerDataVO;
	import com.model.Remote;
	import com.view.Board;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import net.user1.reactor.Attribute;
	import net.user1.reactor.IClient;
	import net.user1.reactor.RoomEvent;
	
	public class MsgController extends EventDispatcher{
		private static var thisObj:MsgController;
		public static const ADDFOOD_AT:String = "adfat";
		public static const ABOUT_DIRECTION:String = "abdrct";
		public static const CHAT_MESSAGE:String = "chtmsg";
		public static var ROOM_NAME:String = "tempwithmdu";
		
		public static const ATR_SS:String = "atrs";
		
		private var remote:Remote;
		private var board:Board;
		public static var classCount:int = 0;
		private var msgTime:Timer = new Timer(120);
		
		public function MsgController(_board:Board){
			classCount++;
			if (classCount>1) {
				throw new Error("Error:Only One Instance Allow Bala..Use MoveController.getInstance() instead of new.");
			}
			trace("dd2 creating remote");
			remote = Remote.getInstance();
			remote.addEventListener(Remote.SERVERREADY,serverReady);
			remote.addEventListener(Remote.UPDATEUSERLIST,updateUserlist);
			thisObj = this;
			board = _board;
			//msgTime.addEventListener(TimerEvent.TIMER,sendMsgTime);
		}
		
		public function startRemoteTiming():void{
			msgTime.start();
		}
		
		private function sendMsgTime(e:TimerEvent):void{
			Remote.getInstance().chatRoom.sendMessage("t",true,null,"t");
		}
		
		protected function gotTime(fromClient:IClient,messageText:String):void {
			trace("dd1 timing..")
			//board.mySnake.moveIt();
		}
		
		private function serverReady(e:Event):void{
			trace("fll serverReady in MsgController ROOM_NAME",ROOM_NAME);
			remote.joinRoom(ROOM_NAME);
			remote.chatRoom.addMessageListener(CustomEvent.ABOUT_SNAKEDATA,gotMessageForSnake);
			remote.chatRoom.addMessageListener(CustomEvent.CHAT_MESSAGE,gotMessageForChat);
			remote.chatRoom.addMessageListener(CustomEvent.ABOUT_DIRECTION,gotMessageForDirections);
			remote.chatRoom.addMessageListener("t",gotTime);
			remote.chatRoom.addEventListener(RoomEvent.UPDATE_CLIENT_ATTRIBUTE,updateClientAttributeListener);
			remote.addEventListener(Remote.SUMBODY_LEFT,somebodyLeft);
		}
		
		public static function getInstance():MsgController{
			return thisObj;
		}
		
		protected function gotMessageForDirections(fromClient:IClient,messageText:String):void {
			MoveController.getInstance().tellToController_GotDirections(fromClient.getAttribute("username"),messageText);
		}
		
		protected function gotMessageForSnake(fromClient:IClient,messageText:String):void {
			trace("dd1 Remote got messageText1=",messageText);
			var tempPlayer:PlayerDataVO = new PlayerDataVO();
			tempPlayer.setStr(messageText);
			tempPlayer.name = fromClient.getAttribute("username");
			trace("dd1 Remote got messageText2=",tempPlayer.getStr());
			MoveController.getInstance().tellToController_Snake(tempPlayer);
		}
		
		protected function gotMessageForChat (fromClient:IClient,messageText:String):void {
			board.incomingMessages.appendText(fromClient.getAttribute("username") + " :: " + messageText+ "\n");
			board.incomingMessages.scrollV = Board.thisObj.incomingMessages.maxScrollV;
		}
		
		//MoveController will call with updated foodData
		public function tellToAllAboutFood():void{
			remote.chatRoom.sendMessage(MsgController.ADDFOOD_AT,true,null,remote.foodData.getString());
		}
		
		// Method invoked when any client in the room
		// changes the value of a shared attribute
		private var takenFoodDataFirstTime:Boolean = false;
		protected function updateClientAttributeListener (e:RoomEvent):void {
			var changedAttr:Attribute = e.getChangedAttr();
			var objj:Object = new Object();
			switch (changedAttr.name){
				case "username":
					if (changedAttr.oldValue == null) {
						Board.thisObj.incomingMessages.appendText("Guest" + e.getClientID());
						objj.oldN = "Guest" + e.getClientID();
					} else {
						Board.thisObj.incomingMessages.appendText(changedAttr.oldValue);
						objj.oldN = changedAttr.oldValue;
					}
					objj.newN =  e.getClient().getAttribute("username");
					trace("ddd Remote dispatching name changed=",objj.oldN," TO ",objj.newN);
					board.updateSnakeName(objj.oldN,objj.newN);
					board.incomingMessages.appendText(" 's name changed to "+ e.getClient().getAttribute("username")+ ".\n");
					board.incomingMessages.scrollV = board.incomingMessages.maxScrollV;
					updateUserlist();
					break;
				case MsgController.ATR_SS:
					var _remoteSnake:RemoteSnake;
					if (e.getClient().isSelf() == false) {
						var xmlStr:String = e.getClient().getAttribute(MsgController.ATR_SS);
						var namee:String = e.getClient().getAttribute("username");
						trace("dd1 got changes for ",namee);
						if(board.allSnakes_vector.length > 0){
							var alreadyExists:Boolean = false;
							for(var i:int = 0; i<board.allSnakes_vector.length; i++){
								if(board.allSnakes_vector[i].playerData.name == namee){
									alreadyExists = true;
									_remoteSnake = RemoteSnake(board.allSnakes_vector[i]);
									break;
								}
							}
							if(alreadyExists == false){
								var temp:PlayerDataVO = new PlayerDataVO();
								temp.name = namee;
								_remoteSnake = board.addNewSnake(temp);
							}
						}
						
						_remoteSnake.setCurrentStatus(xmlStr);
						if(XML(xmlStr).f!=undefined && XML(xmlStr).f!=null){
							takenFoodDataFirstTime = true;
							trace("dd2 gotfood data from first HERO",XML(xmlStr).f.@data)
							board.placeFood_ByRemote(null,XML(xmlStr).f.@data);
						}
					}else{
						trace("dd2 updates from myself..??");
					}
					break;
			}
		}
		
		private function updateUserlist(e:CustomEvent = null):void{
			trace("fll updateUserlist",board);
			board.usersData = ArrayCollection([]);
			for each (var client:IClient in remote.chatRoom.getOccupants()) {
				//board.userlist.appendText(client.getAttribute("username") + "\n");
				var obj:Object = {name:client.getAttribute("username"),img: 'images/Hydrangeas_1.png'};
				board.usersData.addItem(obj);
				//trace("ddd client=",client)
			}
		}
		
		private function somebodyLeft(event:CustomEvent):void{
			var e:RoomEvent = event.data2 as RoomEvent;
			var leftName:String = e.getClient().getAttribute("username");
			trace("left som");
			board.clientLeftRemoveSnake(leftName);
			board.incomingMessages.appendText(leftName + " left the chat.\n");
			board.incomingMessages.scrollV = Board.thisObj.incomingMessages.maxScrollV;
		}
		
		
	}
}