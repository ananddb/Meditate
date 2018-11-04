using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.FitContributor;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Sensor;
using Toybox.UserProfile;

class MediteActivity {
	private var mMeditateModel;
	private var mSession;
	private var mVibeAlertsExecutor;	
	private var mHrvMonitor;
	private var mStressMonitor;
	
	private const SUB_SPORT_YOGA = 43;
		
	function initialize(meditateModel, heartbeatIntervalsSensor) {
		me.mMeditateModel = meditateModel;				
		me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
	}
	
	static function enableHrSensor() {		
		Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );
	}
				
	private function createMinHrDataField() {
		me.mMinHrField = me.mSession.createField(
            "min_hr",
            me.MinHrFieldId,
            FitContributor.DATA_TYPE_UINT16,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"bpm"}
        );

        me.mMinHrField.setData(0);
	}
	
	private const MinHrFieldId = 0;
	private var mMinHrField;
	
	private const RefreshActivityInterval = 1000;
	
	private var mRefreshActivityTimer;
	private var mHeartbeatIntervalsSensor;
			
	function start() {
		if (me.mMeditateModel.isHrvOn()) {
			me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(method(:onOneSecBeatToBeatIntervals));
		}
		if (me.mMeditateModel.getActivityType() == ActivityType.Yoga) { 
			me.mSession = ActivityRecording.createSession(       
                {
                 :name => "Yoga",                              
                 :sport => ActivityRecording.SPORT_TRAINING,      
                 :subSport => SUB_SPORT_YOGA
                });    		
        }
        else {
        	me.mSession = ActivityRecording.createSession(       
                {
                 :name => "Meditating",                              
                 :sport => ActivityRecording.SPORT_GENERIC,      
                 :subSport => ActivityRecording.SUB_SPORT_GENERIC
                });
        }           
		me.createMinHrDataField();	
		me.mHrvMonitor = new HrvMonitor(me.mSession, me.mMeditateModel.getHrvTracking());
		me.mStressMonitor = new StressMonitor(me.mSession, me.mMeditateModel.getHrvTracking());
		me.mSession.start(); 
		me.mVibeAlertsExecutor = new VibeAlertsExecutor(me.mMeditateModel);
		me.mRefreshActivityTimer = new Timer.Timer();		
		me.mRefreshActivityTimer.start(method(:refreshActivityStats), RefreshActivityInterval, true);	
	}	
		
	function onOneSecBeatToBeatIntervals(heartBeatIntervals) {
		if (me.mMeditateModel.isHrvOn()) {		
			me.mHrvMonitor.addOneSecBeatToBeatIntervals(heartBeatIntervals);
			me.mStressMonitor.addOneSecBeatToBeatIntervals(heartBeatIntervals);	
		} 
	}		
			
	function refreshActivityStats() {	
		if (me.mSession.isRecording() == false) {
			return;
	    }	
	    
		var activityInfo = Activity.getActivityInfo();
		if (activityInfo == null) {
			return;
		}
		if (activityInfo.elapsedTime != null) {
			me.mMeditateModel.elapsedTime = activityInfo.elapsedTime / 1000;
		}
		me.mMeditateModel.currentHr = activityInfo.currentHeartRate;
		if (activityInfo.currentHeartRate != null && (me.mMeditateModel.minHr == null || me.mMeditateModel.minHr > activityInfo.currentHeartRate)) {
    		me.mMeditateModel.minHr = activityInfo.currentHeartRate;
    	}
		me.mVibeAlertsExecutor.firePendingAlerts();	 
		me.mMeditateModel.hrvSuccessive = me.mHrvMonitor.calculateHrvSuccessive();
    	
	    Ui.requestUpdate();	    
	}	   	
	
	function stop() {	
		if (me.mSession.isRecording() == false) {
			return;
	    }	
	    if (me.mMeditateModel.isHrvOn()) {
	    	me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
    	}
		me.mSession.stop();		
		me.mRefreshActivityTimer.stop();
		me.mRefreshActivityTimer = null;
		me.mVibeAlertsExecutor = null;
	}
		
	function calculateSummaryFields() {		
		var activityInfo = Activity.getActivityInfo();		
		if (me.mMeditateModel.minHr != null) {
			me.mMinHrField.setData(me.mMeditateModel.minHr);
		}
		
		var stress = me.mStressMonitor.calculateStress(me.mMeditateModel.minHr);

		var hrvSummary = me.mHrvMonitor.calculateHrvSummary();
		var summaryModel = new SummaryModel(activityInfo, me.mMeditateModel.minHr, stress, hrvSummary, me.mMeditateModel.getHrvTracking());
		return summaryModel;
	}
			
	function finish() {		
		me.mSession.save();
		me.mSession = null;
	}
		
	function discard() {		
		me.mSession.discard();
		me.mSession = null;
	}
	
	function discardDanglingActivity() {
		var isDangling = me.mSession != null && !me.mSession.isRecording();
		if (isDangling) {
			me.discard();
		}
	}
}