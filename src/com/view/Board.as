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
	//echo ".actionScriptProperties" >> .gitignore
	//git rm --cached .actionScriptProperties
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
		public var RoomName:String="a";
		
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
			stage.addEventListener(KeyboardEvent.KEY_DOWN,updateMySnakeSpeed);
			stage.addEventListener(KeyboardEvent.KEY_UP,updateMySnakeSpeed);
		}
		
		private function init():void{
			//add Remote Listeners..
			Remote.getInstance().addEventListener(Remote.IJOINED_ADDMYSNAKE,iJoined_AddMySnake);
			var sp:Shape = new Shape();
			sp.graphics.beginFill(0xcccccc,.3);
			sp.graphics.lineStyle(1,0xcccccc);
			sp.graphics.drawRect(0,0,width,height-5);
			addChild(sp);
		}
		
		//SSS xx=200;yy=200;col=0xff00ff;
		
		public var meClient:IClient;
		private function iJoined_AddMySnake(e:CustomEvent):void{
			for each (var client2:IClient in Remote.getInstance().chatRoom.getOccupants()) {
				if(client2.isSelf()){
					meClient = client2;
				}
			}
			Remote.playerData.col = Math.random() * 0xFFFFFF;
			mySnake = new MySnake(Remote.playerData.col);
			mySnake.playerData = e.data;
			mySnake.playerData.col = Remote.playerData.col;
			Remote.getInstance().setMyFBData(baseMXML.myFBookName,baseMXML.myFBookID,baseMXML.myFBookIMG);
			Remote.getInstance().chatRoom.sendMessage("justUpdate",true,null,"justit");
			Remote.getInstance().chatRoom.sendMessage(CustomEvent.IJOINED,true,null,e.data.getStr());
			trace("dd7 iJoined_AddMySnake and sending messageIJOIned in",baseMXML.myFBookName,"col=",mySnake.playerData.col);
		}
		
		
		//msgController..
		public function iJoinedByRemote(me:Boolean,pData:PlayerDataVO):void{
			//trace("dd6 iJoinedRemote=",pData.unm);
			if(me == true){
				trace("dd7 iJoinedByRemote me=",pData.unm," in",baseMXML.myFBookName);
				mySnake.addEventListener(MySnake.I_GOT_FOOD,MoveController.getInstance().tellToController_MYSnakeGotFood);
				Remote.getInstance().chatRoom.addMessageListener(MsgController.ADDFOOD_AT,placeFood_ByRemote);
				Remote.getInstance().chatRoom.addMessageListener("died",someOneDied);
				mySnake.addEventListener(CustomEvent.MY_KEY_DATA_TO_SEND,MoveController.getInstance().tellToController_ToSendDirections);
				mySnake.addEventListener("died",iDiedTellToAll);
				addChild(mySnake);
				allSnakes_vector.push(mySnake);
				inComingChatMsg = inComingChatMsg + "You joined the chat.\n";
				checkUFirst();
				mySnake.timer.reset();
				mySnake.timer.start();
			}else{
				trace("dd7 iJoinedByRemote Notme=",pData.unm," in",baseMXML.myFBookName);
				addNewSnake(pData);
				inComingChatMsg = inComingChatMsg + pData.unm + " joined the chat.\n";
				mySnake.timer.reset();
				trace("dd7 updating.. ATR_SS for",baseMXML.myFBookName);
				meClient.setAttribute("col",String(mySnake.playerData.col));
				meClient.setAttribute(MsgController.ATR_SS,mySnake.currentStatusOfMySnake(true));
			}
		}
		
		public function clientLeftRemoveSnake(cName:String):void{
			for(var i:int = 0; i<allSnakes_vector.length; i++){
				if(allSnakes_vector[i].playerData.unm == cName){
					var removedSnake:Snake = allSnakes_vector.splice(i,1)[0];
					if(removedSnake.parent){
						removeChild(removedSnake);
						trace("dd1 removed Snake for",removedSnake.playerData.unm);
					}
				}
			}
		}
		
		private function checkUFirst():void{
			var tempList:int = 0;
			for each (var client:IClient in Remote.getInstance().chatRoom.getOccupants()) {
				tempList++;
			}
			if(tempList>1){
				
			}else{
				Board.IFirst = true;
				//MsgController.getInstance().startRemoteTiming();
				MoveController.getInstance().placeApple(mySnake.snake_vector,false);
			}
		}
		
		private var downed:Boolean = false;
		private function updateMySnakeSpeed(e:KeyboardEvent):void{
			if(MsgController.ServerReady == true){
				if (downed == false && e.type == KeyboardEvent.KEY_DOWN && e.keyCode == Keyboard.CONTROL){
					meClient.setAttribute(MsgController.ATR_TT,"30");
					downed = true;
					trace("dd6 set  SPEED UP 30",Remote.playerData.unm);
				}
				
				if (e.type == KeyboardEvent.KEY_UP && e.keyCode == Keyboard.CONTROL){
					downed = false;
					meClient.setAttribute(MsgController.ATR_TT,"100");
					trace("dd6 set BAck SPEED Default",Remote.playerData.unm);
				}
			}
		}
		//call from msgController for first time by First Hero
		public function placeFood_ByRemote (fromClient:IClient=null,messageText:String=""):void {
			//placeApple(mySnake.snake_vector);
			trace("dd5 placeFood ByRemote")
			if(MoveController.thisObj.apple == null){
				MoveController.thisObj.apple = new Element(0xFF0000,1,10, 10);
			}
			trace("dd1 placeFood_ByRemote messageText",messageText);
			Remote.getInstance().foodData.setString(messageText);
			addChild(MoveController.thisObj.apple);
			MoveController.thisObj.apple.x = Remote.getInstance().foodData.xx;
			MoveController.thisObj.apple.y = Remote.getInstance().foodData.yy;
		}
		
		//msgController can use for before you snake..
		public function addNewSnake(playerData:PlayerDataVO):RemoteSnake{
			trace("dd6 got col=",playerData.col)
			var tempRemoteSnake:RemoteSnake = new RemoteSnake(playerData.col);
			tempRemoteSnake.playerData = playerData;
			addChild(tempRemoteSnake);
			allSnakes_vector.push(tempRemoteSnake);
			tempRemoteSnake.timer.reset();
			tempRemoteSnake.timer.start();
			trace("ddd addNewSnake in Board  for player=",playerData.unm," allSnakes.length=",allSnakes_vector.length);
			return tempRemoteSnake;
		}
		private function someOneDied(fromClient:IClient=null,messageText:String=""):void {
			var namee:String = fromClient.getAttribute("unm");
			for(var i:int = 0; i<allSnakes_vector.length; i++){
				if(allSnakes_vector[i].playerData.unm == namee){
					trace("dd8 restarted snake of ",namee," in ",baseMXML.myFBookName)
					Snake(allSnakes_vector[i]).reStartSnake();
				}
			}
		}
		private function iDiedTellToAll(e:Event):void{
			Remote.getInstance().chatRoom.sendMessage("died",true,null,"oh");
		}
	}
}