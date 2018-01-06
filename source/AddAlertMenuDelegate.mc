using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class AddAlertMenuDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }
		
    function onMenuItem(item) {
        if (item == :color) {
	        Ui.popView(Ui.SLIDE_IMMEDIATE);
	        var colors = [Gfx.COLOR_BLUE, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW];
	        
	        Ui.pushView(new ColorPickerView(Gfx.COLOR_BLUE), new ColorPickerDelegate(colors, method(:onColorSelected)), Ui.SLIDE_RIGHT);
        }
        else if (item == :time) {
        	var durationPickerModel = new DurationPickerModel();
	        Ui.popView(Ui.SLIDE_IMMEDIATE);
    		Ui.pushView(new DurationPickerView(durationPickerModel), new DurationPickerDelegate(durationPickerModel, me.mMeditateModel), Ui.SLIDE_RIGHT);
        }
    }
    
    function onColorSelected(color) {
    	System.println("color: " + color);
    }

}