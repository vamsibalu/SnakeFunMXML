package com.Elements
{
	import com.events.CustomEvent;
	import com.model.Remote;
	import com.view.Board;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	public class MySnake extends Snake implements ISnake{
		
		public static const I_GOT_FOOD:String = "igotfood";
		
		public function MySnake(){
			super(false);
			addEventListener(Event.ADDED_TO_STAGE,addedToStage);
		}
		
		private function addedToStage(e:Event):void{
			stage.addEventListener(KeyboardEvent.KEY_DOWN,directionChanged);
		}
		
		private function directionChanged(e:KeyboardEvent):void {
			var m:Object = new Object(); //MARKER OBJECT
			var directionChanged:Boolean = false;
			if (e.keyCode == Keyboard.LEFT && last_button_down != e.keyCode && last_button_down != Keyboard.RIGHT && flag)
			{
				playerData.directon = "LL";
				directionChanged = true;
				snake_vector[0].direction = "L";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"L"};
				last_button_down = Keyboard.LEFT;
				flag = false;
			}
			else if (e.keyCode == Keyboard.RIGHT && last_button_down != e.keyCode && last_button_down != Keyboard.LEFT && flag)
			{
				playerData.directon = "RR";
				directionChanged = true;
				snake_vector[0].direction = "R";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"R"};
				last_button_down = Keyboard.RIGHT;
				flag = false;
			}
			else if (e.keyCode == Keyboard.UP && last_button_down != e.keyCode && last_button_down != Keyboard.DOWN && flag)
			{
				playerData.directon = "UU";
				directionChanged = true;
				snake_vector[0].direction = "U";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"U"};
				last_button_down = Keyboard.UP;
				flag = false;
			}
			else if (e.keyCode == Keyboard.DOWN && last_button_down != e.keyCode && last_button_down != Keyboard.UP && flag)
			{
				playerData.directon = "DD";
				directionChanged = true;
				snake_vector[0].direction = "D";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"D"};
				last_button_down = Keyboard.DOWN;
				flag = false;
			}
			
			markers_vector.push(m);
			
			if(directionChanged == true){
				dispatchEvent(new CustomEvent(CustomEvent.MY_KEY_DATA_TO_SEND,playerData));
			}
			trace("dd2 markers_vector",markers_vector.length);
		}
		
		public function currentStatusOfMySnake(needFoodData:Boolean):String{
			var xml:String = "<o>";
			for(var i:int = 0; i<snake_vector.length; i++){
				var nm:XML =  <n x={snake_vector[i].x} y={snake_vector[i].y} d={snake_vector[i].direction}/>
				xml = xml + nm.toXMLString();
			}
			trace("dd2 currentStatusOfMySnake_______________________")
			//send markers details aswell..
			for(var j:int = 0; j<markers_vector.length; j++){
				var m:XML =  <m x={markers_vector[j].x} y={markers_vector[j].y} type={markers_vector[j].type}/>
				xml = xml + m.toXMLString();
				trace("dd2 settingmarkersMYsnake=",m.@type);
			}
			
			if(Board.IFirst == true && needFoodData == true){
				trace("dd2 adding <f data");
				var foodData:String = Remote.getInstance().foodData.getString();
				var ff:XML =  <f data={foodData}/>
				xml = xml + ff.toXMLString();
			}
			xml = xml+"</o>";
			return xml;
		}
	}
}