package com.controller
{
	import com.Elements.Element;
	import com.Elements.MySnake;
	import com.Elements.RemoteSnake;
	import com.events.CustomEvent;
	import com.model.FoodDataVo;
	import com.model.PlayerDataVO;
	import com.model.Remote;
	import com.view.Board;
	
	import comps.BoardComp;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.core.INavigatorContent;
	
	import net.user1.reactor.IClient;
	
	public class MoveController extends EventDispatcher{
		public static var thisObj:MoveController;
		public var apple:Element; //Our apple
		private var space_value:Number; //space between the snake parts
		private var view:BoardComp;
		public static var classCount:int = 0;
		private var tempF:FoodDataVo = new FoodDataVo();
		public function MoveController(_view:BoardComp){
			thisObj = this;
			space_value = 2;
			view = _view;
			//listen for gotfood event that snake will dispatch upon (hit && remoteSnake == false);
			classCount++;
			if (classCount>1) {
				throw new Error("Error:Only Instance Allow Bala..Use MoveController.getInstance() instead of new.");
			}
			Remote.getInstance().addEventListener(Remote.SUMBODY_BEFORE_YOU,checkForBoforeYou);
		}
		
		private function checkForBoforeYou(e:CustomEvent):void{
			trace("dd1 checkForBoforeYou=",e.data2);
			if(e.data2 == true){
				for each (var client2:IClient in Remote.getInstance().chatRoom.getOccupants()) {
					trace("xx ddd",client2.getAttribute("xx"));
				}
			}else{
				trace("dd1 iam first i can place food");
				Board.IFirst = true;
				//MsgController.getInstance().startRemoteTiming();
				placeApple(view.board.mySnake.snake_vector,false);
			}
		}
		
		public static function getInstance():MoveController{
			return thisObj;
		}
		
		public function tellToController_MYSnakeGotFood(e:Event):void{
			//update my snake so everybody know about me...
			if(Remote.getInstance().foodData.fname == Remote.getInstance().chatRoom.getAttribute("ff")){
				trace("dd5 you deserve food..",Remote.getInstance().chatRoom.getAttribute("ff")," you",Remote.playerData.name);
				view.board.mySnake.iGotFoodAddMyElement();
				updateMySnake_isSlef();
				placeApple(view.board.mySnake.snake_vector,true);
			}else{
				trace("dd5 food",Remote.getInstance().chatRoom.getAttribute("ff")," somebody already taken...you can't w8 ra ",Remote.playerData.name)
			}
		}
		
		public function tellToController_Snake(data:PlayerDataVO):void{
			for(var i:int = 0; i<view.board.allSnakes_vector.length; i++){
				if((view.board.allSnakes_vector[i].playerData.name == data.name) && (view.board.allSnakes_vector[i] is RemoteSnake)){
					trace("ddd modifying remoteSnake for",data.name);
					break;
				}
				trace("ddd allSnakes_vector[i].playerData.name",view.board.allSnakes_vector[i].playerData.name," e.data.name=",data.name," allSnakes_vector.length=",view.board.allSnakes_vector.length)
			}
		}
		
		public function tellToController_GotDirections(senderName:String,msg:String):void{
			for(var i:int = 0; i<view.board.allSnakes_vector.length; i++){
				if((view.board.allSnakes_vector[i].playerData.name == senderName) && (view.board.allSnakes_vector[i] is RemoteSnake)){
					trace("ddd modifying remoteSnake Directions for",senderName);
					RemoteSnake(view.board.allSnakes_vector[i]).directionChanged(msg);
					break;
				}
				//trace("ddd allSnakes_vector[i].playerData.name",view.board.allSnakes_vector[i].playerData.name," senderName=",senderName," allSnakes_vector.length=",view.board.allSnakes_vector.length)
			}
		}
		
		//send message for Direction and 
		public function tellToController_ToSendDirections(e:CustomEvent):void{
			//update my snake so everybody know about me...
			updateMySnake_isSlef();
			
			var tempMsg:String = e.data.directon;
			Remote.getInstance().chatRoom.sendMessage(MsgController.ABOUT_DIRECTION,true,null,tempMsg);
		}
		
		private function updateMySnake_isSlef():void{
			for each (var client:IClient in Remote.getInstance().chatRoom.getOccupants()) {
				if(client.isSelf()){
					client.setAttribute(MsgController.ATR_SS,Board.thisObj.mySnake.currentStatusOfMySnake(false));
					trace("dd2 did setAttributes of mysnake");
				}
			}
		}
		
		private function placeApple(snake_vector:Vector.<Element>,caught:Boolean = true):void{
			trace("dd5 placeApple")
			if(apple == null){
				apple = new Element(0xFF0000,1,10, 10);
			}
			apple.catchValue = 0;
			
			if (caught)
				apple.catchValue += 10;
			
			var boundsX:int = (Math.floor(Board.WIDTH / (snake_vector[0].width + space_value)))-1;
			var randomX:Number = Math.floor(Math.random()*boundsX);
			
			var boundsY:int = (Math.floor(Board.HEIGHT/(snake_vector[0].height + space_value)))-1;
			var randomY:Number = Math.floor(Math.random()*boundsY);
			
			apple.x = randomX * (apple.width + space_value);
			apple.y = randomY * (apple.height + space_value);
			
			for(var i:uint=0;i<snake_vector.length-1;i++)
			{
				if(snake_vector[i].x == apple.x && snake_vector[i].y == apple.y)
					placeApple(snake_vector,false);
			}
			
			//now place apple anywhere
			var fcounts:int
			trace("dd5 fcounts",Remote.getInstance().chatRoom.getAttribute("ff"));
			if(Remote.getInstance().chatRoom.getAttribute("ff")){
				fcounts = int(Remote.getInstance().chatRoom.getAttribute("ff").split("fd")[1]);
				fcounts++;
			}else{
				fcounts = 0;
			}
			trace("dd5 fcounts++",fcounts);
			tempF.fname = "fd"+fcounts;
			//tempF.col = Math.random();
			tempF.xx = apple.x;
			tempF.yy = apple.y;
			Remote.getInstance().foodData = tempF;
			MsgController.getInstance().tellToAllAboutFood();
		}
	}
}