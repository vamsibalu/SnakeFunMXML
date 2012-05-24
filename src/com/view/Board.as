package com.view
{
	import com.Elements.Element;
	import com.Elements.MySnake;
	import com.Elements.RemoteSnake;
	import com.Elements.Snake;
	import com.controller.MoveController;
	import com.controller.MsgController;
	import com.events.CustomEvent;
	import com.model.PlayerDataVO;
	import com.model.Remote;
	import com.utils.UIObj;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	
	import net.user1.reactor.IClient;
	import net.user1.reactor.RoomEvent;
	
	public class Board extends UIComponent
	{
		public var mySnake:MySnake;
		
		public var allSnakes_vector:Vector.<Snake> = new Vector.<Snake>();
		public static var thisObj:Board;
		public static var IFirst:Boolean = false;
		public static var WIDTH:Number = 550;
		public static var HEIGHT:Number = 400;
		
		[Bindable]             
		public var usersData:ArrayCollection;
		
		[Bindable]             
		public var RoomName:String="badroom";
		
		[Bindable]             
		public var inComingChatMsg:String="Simple Chat Msg...";
		
		public var baseMXML:SnakeFunMXML;
		
		
		public function Board(){
			
		}
		
		public function createBoard(_base:SnakeFunMXML):void{
			WIDTH = width;
			HEIGHT = height;
			baseMXML = _base;
			thisObj = this;
			init();
		}
		
		private function init():void{
			//add Remote Listeners..
			Remote.getInstance().addEventListener(Remote.IJOINED_ADDMYSNAKE,iJoined_AddMySnake);
			var sp:Shape = new Shape();
			sp.graphics.beginFill(0xcccccc,.3);
			sp.graphics.lineStyle(1,0xcccccc);
			sp.graphics.drawRect(0,0,width,height);
			addChild(sp);
		}
		
		//SSS xx=200;yy=200;col=0xff00ff;
		private function iJoined_AddMySnake(e:CustomEvent):void{
			//add my snake;
			if(e.data is PlayerDataVO){
				Remote.getInstance().setMyFBData(baseMXML.myFBookName,baseMXML.myFBookID,baseMXML.myFBookIMG);
				Remote.getInstance().chatRoom.sendMessage("justUpdate",true,null,"justit");
				mySnake = new MySnake();
				mySnake.playerData = e.data;
				mySnake.addEventListener(MySnake.I_GOT_FOOD,MoveController.getInstance().tellToController_MYSnakeGotFood);
				Remote.getInstance().chatRoom.addMessageListener(MsgController.ADDFOOD_AT,placeFood_ByRemote);
				mySnake.addEventListener(CustomEvent.MY_KEY_DATA_TO_SEND,MoveController.getInstance().tellToController_ToSendDirections);
				addChild(mySnake);
				allSnakes_vector.push(mySnake);
				inComingChatMsg = inComingChatMsg + "You joined the chat.\n";
				trace("dd1 iJoined_AddMySnake my name",mySnake.playerData.name);
			}else{
				var roomEvent:RoomEvent = RoomEvent(e.data2);
				var nameee:String = roomEvent.getClient().getAttribute("unm");
				inComingChatMsg = inComingChatMsg + nameee + " joined the chat.\n";
				var tempPlayer:PlayerDataVO = new PlayerDataVO();
				tempPlayer.name = nameee;
				addNewSnake(tempPlayer);
				trace("dd1 somebody joined his name=",tempPlayer.name);
				//update my snake so he know about me...
				for each (var client:IClient in Remote.getInstance().chatRoom.getOccupants()) {
					if(client.isSelf()){
						client.setAttribute(MsgController.ATR_SS,mySnake.currentStatusOfMySnake(true));
						trace("dd1 did setAttributes of mysnake");
					}
				}
			}
		}
		
		public function clientLeftRemoveSnake(cName:String):void{
			for(var i:int = 0; i<allSnakes_vector.length; i++){
				if(allSnakes_vector[i].playerData.name == cName){
					var removedSnake:Snake = allSnakes_vector.splice(i,1)[0];
					if(removedSnake.parent){
						removeChild(removedSnake);
						trace("dd1 removed Snake for",removedSnake.playerData.name);
					}
				}
			}
		}
		
		public function resetSnakeTime(fromClient:IClient,messageText:String):void {
			mySnake.timer.reset();
			mySnake.timer.start();
		}
		//call from msgController for first time by First Hero
		public function placeFood_ByRemote (fromClient:IClient=null,messageText:String=""):void {
			//placeApple(mySnake.snake_vector);
			if(MoveController.apple == null){
				MoveController.apple = new Element(0xFF0000,1,10, 10);
			}
			trace("dd1 placeFood_ByRemote messageText",messageText);
			Remote.getInstance().foodData.setString(messageText);
			addChild(MoveController.apple);
			MoveController.apple.x = Remote.getInstance().foodData.xx;
			MoveController.apple.y = Remote.getInstance().foodData.yy;
		}
		
		//msgController can use for before you snake..
		public function addNewSnake(playerData:PlayerDataVO):RemoteSnake{
			var tempRemoteSnake:RemoteSnake = new RemoteSnake();
			tempRemoteSnake.playerData = playerData;
			addChild(tempRemoteSnake);
			allSnakes_vector.push(tempRemoteSnake);
			trace("ddd addNewSnake in Board  for player=",playerData.name," allSnakes.length=",allSnakes_vector.length);
			return tempRemoteSnake;
		}
	}
}