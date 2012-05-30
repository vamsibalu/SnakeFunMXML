package com.controller
{
	import com.Elements.MySnake;
	import com.Elements.RemoteSnake;
	import com.Elements.Snake;
	import com.events.CustomEvent;
	import com.model.PlayerDataVO;
	import com.model.Remote;
	import com.view.Board;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectProxy;
	
	import net.user1.reactor.Attribute;
	import net.user1.reactor.IClient;
	import net.user1.reactor.RoomEvent;
	
	public class MsgController extends EventDispatcher{
		private static var thisObj:MsgController;
		public static const ADDFOOD_AT:String = "adfat";
		public static const ABOUT_DIRECTION:String = "abdrct";
		public static const CHAT_MESSAGE:String = "chtmsg";
		public static var ROOM_NAME:String = "tempwithmdu";
		
		public static const ATR_SS:String = "atsnk";
		public static const ATR_TT:String = "ttatr";
		
		private var remote:Remote;
		private var board:Board;
		public static var classCount:int = 0;
		public static var ServerReady:Boolean;
		
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
		
		private function sendMsgTime(e:TimerEvent):void{
			Remote.getInstance().chatRoom.sendMessage("t",true,null,"t");
		}
		
		private function serverReady(e:Event):void{
			ServerReady = true;
			trace("dd6 serverReady in MsgController ROOM_NAME",ROOM_NAME);
			board.RoomName = ROOM_NAME;
			remote.joinRoom(ROOM_NAME);
			remote.chatRoom.addMessageListener(CustomEvent.ABOUT_SNAKEDATA,gotMessageForSnake);
			remote.chatRoom.addMessageListener(CustomEvent.CHAT_MESSAGE,gotMessageForChat);
			remote.chatRoom.addMessageListener(CustomEvent.ABOUT_DIRECTION,gotMessageForDirections);
			remote.chatRoom.addMessageListener(CustomEvent.IJOINED,iJoinedRemote);
			
			remote.chatRoom.addEventListener(RoomEvent.UPDATE_CLIENT_ATTRIBUTE,updateClientAttributeListener);
			remote.addEventListener(Remote.SUMBODY_LEFT,somebodyLeft);
		}
		
		public static function getInstance():MsgController{
			return thisObj;
		}
		
		protected function iJoinedRemote(fromClient:IClient,messageText:String):void {
			var tempD:PlayerDataVO = new PlayerDataVO();
			tempD.setStr(messageText);
			trace("dd7 got messageText=",messageText," in ",board.baseMXML.myFBookName)
			board.iJoinedByRemote(fromClient.isSelf(),tempD);
		}
		
		protected function gotMessageForDirections(fromClient:IClient,messageText:String):void {
			MoveController.getInstance().tellToController_GotDirections(fromClient.getAttribute("unm"),messageText);
		}
		
		protected function gotMessageForSnake(fromClient:IClient,messageText:String):void {
			trace("dd1 Remote got messageText1=",messageText);
			var tempPlayer:PlayerDataVO = new PlayerDataVO();
			tempPlayer.setStr(messageText);
			tempPlayer.unm = fromClient.getAttribute("unm");
			trace("dd1 Remote got messageText2=",tempPlayer.getStr());
			MoveController.getInstance().tellToController_Snake(tempPlayer);
		}
		
		protected function gotMessageForChat (fromClient:IClient,messageText:String):void {
			board.inComingChatMsg = board.inComingChatMsg + fromClient.getAttribute("unm") + " :: " + messageText+ "\n";
			//board.incomingMessages.scrollV = Board.thisObj.incomingMessages.maxScrollV;
		}
		
		//MoveController will call with updated foodData
		public function tellToAllAboutFood():void{
			remote.chatRoom.sendMessage(MsgController.ADDFOOD_AT,true,null,remote.foodData.getString());
		}
		
		// Method invoked when any client in the room
		// changes the value of a shared attribute
		protected function updateClientAttributeListener (e:RoomEvent):void {
			var changedAttr:Attribute = e.getChangedAttr();
			var namee:String = e.getClient().getAttribute("unm");
			switch (changedAttr.name){
				case MsgController.ATR_SS:
					var _remoteSnake:RemoteSnake;
					if (e.getClient().isSelf() == false) {
						var xmlStr:String = e.getClient().getAttribute(MsgController.ATR_SS);
						trace("dd7 got ATR_SS changes for ",namee,"in ",board.baseMXML.myFBookName);
						if(board.allSnakes_vector.length > 0){
							var alreadyExists:Boolean = false;
							for(var i:int = 0; i<board.allSnakes_vector.length; i++){
								if(board.allSnakes_vector[i].playerData.unm == namee){
									alreadyExists = true;
									_remoteSnake = RemoteSnake(board.allSnakes_vector[i]);
									break;
								}
							}
							if(alreadyExists == false){
								var temp:PlayerDataVO = new PlayerDataVO();
								temp.unm = namee;
								temp.col = int(e.getClient().getAttribute("col"));
								trace("dd7 alreadyExists == false col=",temp.col," in =",board.baseMXML.myFBookName);
								_remoteSnake = board.addNewSnake(temp);
							}
						}
						
						_remoteSnake.setCurrentStatus(xmlStr);
						if(XML(xmlStr).f!=undefined && XML(xmlStr).f!=null){
							trace("dd2 gotfood data from first HERO",XML(xmlStr).f.@data)
							board.placeFood_ByRemote(null,XML(xmlStr).f.@data);
						}
					}else{
						board.mySnake.timer.start();
						trace("dd2 updates from myself..??");
					}
					break;
				case MsgController.ATR_TT:
					var tempSnake:Snake;
					trace("dd6 got ATR TT for ",namee,"Speed",changedAttr.value," on Board",Remote.playerData.unm);
					for(var k:int = 0; k<board.allSnakes_vector.length; k++){
						if(board.allSnakes_vector[k].playerData.unm == namee){
							tempSnake = Snake(board.allSnakes_vector[k]);
							break;
						}
					}
					tempSnake.timer.reset();
					trace("dd6 setting delay ",Number(changedAttr.value),tempSnake.playerData.unm)
					tempSnake.timer.delay = Number(changedAttr.value);
					tempSnake.timer.start();
					break
			}
		}
		
		private function updateUserlist(e:CustomEvent):void{
			trace("fll updateUserlist_______");
			var ary:Array = [];
			for each (var client:IClient in remote.chatRoom.getOccupants()) {
				var namee:String = client.getAttribute("unm");
				var idd:String = client.getAttribute("uid");
				var imgg:String = client.getAttribute("uimg");
				trace("fll name=",namee)
				var obj:Object = {unm:namee,uid:idd,uimg:imgg};
				ary.push(obj);
			}
			board.usersData = new ArrayCollection(ary);
		}
		
		private function somebodyLeft(event:CustomEvent):void{
			var e:RoomEvent = event.data2 as RoomEvent;
			var leftName:String = e.getClient().getAttribute("unm");
			trace("left som",leftName);
			board.clientLeftRemoveSnake(leftName);
			board.inComingChatMsg = board.inComingChatMsg +leftName + " left the chat.\n";
			//board.incomingMessages.scrollV = Board.thisObj.incomingMessages.maxScrollV;
		}
		
		
	}
}