/**
 * @author Balakrishna [vamsibalu@gmail.com]
 * @version 2.0
 */
package com.Elements
{
	import flash.ui.Keyboard;
	
	public class RemoteSnake extends Snake implements ISnake{
		
		public function RemoteSnake(){
			super(true);
		}
		
		//hey bala use this function with RemoteData;
		public function directionChanged(direction:String):void {
			var m:Object = new Object(); //MARKER OBJECT
			
			if (direction == "LL")
			{
				snake_vector[0].direction = "L";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"L"};
				last_button_down = Keyboard.LEFT;
				flag = false;
			}
			else if (direction == "RR")
			{
				snake_vector[0].direction = "R";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"R"};
				last_button_down = Keyboard.RIGHT;
				flag = false;
			}
			else if (direction == "UU")
			{
				snake_vector[0].direction = "U";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"U"};
				last_button_down = Keyboard.UP;
				flag = false;
			}
			else if (direction == "DD")
			{
				snake_vector[0].direction = "D";
				m = {x:snake_vector[0].x, y:snake_vector[0].y, type:"D"};
				last_button_down = Keyboard.DOWN;
				flag = false;
			}
			markers_vector.push(m);
		}
		
		public function setCurrentStatus(xmlStr:String):void{
			var xml:XML = XML(xmlStr);
			trace("dd1 applying setCurrentStatus",playerData.name,xml.n.length());
			for(var i:int = 0; i<xml.n.length(); i++){
				if(snake_vector.length>i){
					trace("already element is there");
				}else{
					snake_vector[i] = new Element(0x00AAFF,1,10,10);
				}
				trace("dd1 snake_vector[i] data==",xml.n[i].@x,xml.n[i].@y,xml.n[i].@d)
				snake_vector[i].direction = xml.n[i].@d;
				snake_vector[i].x = xml.n[i].@x;
				snake_vector[i].y = xml.n[i].@y;
				super.addChild(snake_vector[i]);
			}
			
			//for markers
			var tempMarks:Vector.<Object> = new Vector.<Object>;
			for(var j:int = 0; j<xml.m.length(); j++){
				var m:Object = new Object(); //MARKER OBJECT
				m.x = xml.m[j].@x;
				m.y = xml.m[j].@y;
				m.type = xml.m[j].@type;
				flag = false;
				tempMarks.push(m);
				trace("dd2 gotmarkersRemotesnake=",m.type);
			}
			markers_vector = tempMarks;
		}
	}
}